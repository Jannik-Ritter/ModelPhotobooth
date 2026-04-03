local CoreGui = game:GetService("CoreGui")
local AssetService = game:GetService("AssetService")

local Packages = script.Parent.Parent.Parent.Packages
local Promise = require(Packages.promise)
local Types = require(script.Parent.Parent.Types)

local applyCamera = require(script.Parent.applyCamera)
local animationHelpers = require(script.Parent.animationHelpers)
local getBoundsSnapshot = require(script.Parent.viewportBounds)
local getRenderScale = require(script.Parent.getRenderScale)
local postProcess = require(script.Parent.postProcess)
local waitForAnimationTrackLength = require(script.Parent.Parent.utils.waitForAnimationTrackLength)
local snapScreenshot = require(script.Parent.Parent.utils.snapScreenshot)
local Constants = require(script.Parent.Parent.Constants)

type RenderSettings = Types.RenderSettings
type CaptureViewport = Types.CaptureViewport

local applyAnimationPoseAtTime = animationHelpers.applyAnimationPoseAtTime
local getOrCreateAnimator = animationHelpers.getOrCreateAnimator

local function setupAnimation(modelClone: Instance, viewport: ViewportFrame, settings: RenderSettings)
	if not settings.animationId or settings.animationId == "" then
		return
	end

	local wm = Instance.new("WorldModel")
	wm.Parent = viewport
	modelClone.Parent = wm

	local animator = getOrCreateAnimator(modelClone)
	if not animator then
		return
	end

	local animObj = Instance.new("Animation")
	animObj.AnimationId = settings.animationId

	local track
	local loadOk = pcall(function()
		track = animator:LoadAnimation(animObj)
	end)
	animObj:Destroy()

	if not (loadOk and track) then
		return
	end

	track.Priority = Enum.AnimationPriority.Action4
	track.Looped = true
	track:Play(0)

	local okLength = waitForAnimationTrackLength(track, Constants.MAX_POLL_ATTEMPTS):await()
	if not okLength then
		return
	end

	for _ = 1, Constants.POSE_STEP_COUNT do
		applyAnimationPoseAtTime(animator, track, settings.animationTimePosition or 0)
	end
	task.wait(Constants.POLL_INTERVAL)
end

local function createCaptureViewport(
	model: Instance,
	settings: RenderSettings,
	capSize: number
): (CaptureViewport?, string?)
	local tmpGui = Instance.new("ScreenGui")
	tmpGui.Name = "_MPhotoCapture"
	tmpGui.ResetOnSpawn = false
	tmpGui.DisplayOrder = Constants.ZINDEX_OVERLAY
	tmpGui.IgnoreGuiInset = true
	tmpGui.Parent = CoreGui

	local bgFr = Instance.new("Frame")
	bgFr.Size = UDim2.fromScale(1, 1)
	bgFr.BorderSizePixel = 0
	bgFr.Parent = tmpGui

	local tmpVP = Instance.new("ViewportFrame")
	tmpVP.Size = UDim2.fromOffset(capSize, capSize)
	tmpVP.Position = UDim2.new(0.5, -capSize / 2, 0.5, -capSize / 2)
	tmpVP.BorderSizePixel = 0
	tmpVP.Ambient = settings.lighting.ambient
	tmpVP.LightDirection = Vector3.new(
		settings.lighting.lightDirectionX,
		settings.lighting.lightDirectionY,
		settings.lighting.lightDirectionZ
	)
	tmpVP.LightColor = settings.lighting.lightColor
	tmpVP.Parent = tmpGui

	local tmpCam = Instance.new("Camera")
	tmpCam.Parent = tmpVP
	tmpVP.CurrentCamera = tmpCam

	local tmpClone
	local ok = pcall(function()
		tmpClone = model:Clone()
		tmpClone.Parent = tmpVP
	end)
	if not ok or not tmpClone then
		tmpGui:Destroy()
		return nil, "failed to clone model"
	end

	return {
		gui = tmpGui,
		bgFrame = bgFr,
		viewport = tmpVP,
		camera = tmpCam,
		modelClone = tmpClone,
	}, nil
end

local function snapBackground(bgFrame: Frame, viewport: ViewportFrame, bg: Color3): (boolean, EditableImage?, string?)
	bgFrame.BackgroundColor3 = bg
	viewport.BackgroundColor3 = bg
	task.wait(Constants.FRAME_DT)

	local ok, result = snapScreenshot(1, Constants.POLL_INTERVAL):await()
	if not ok then
		return false, nil, tostring(result)
	end
	return true, result, nil
end

local function extractAlpha(
	bgFrame: Frame,
	viewport: ViewportFrame,
	cropPos: Vector2,
	cropSz: Vector2
): (buffer?, number, number, string?)
	local okWhite, whiteImage, errWhite = snapBackground(bgFrame, viewport, Color3.new(1, 1, 1))
	if not okWhite then
		return nil, 0, 0, errWhite
	end

	local okBlack, blackImage, errBlack = snapBackground(bgFrame, viewport, Color3.new(0, 0, 0))
	if not okBlack then
		whiteImage:Destroy()
		return nil, 0, 0, errBlack
	end

	local whiteBuf = whiteImage:ReadPixelsBuffer(cropPos, cropSz)
	local blackBuf = blackImage:ReadPixelsBuffer(cropPos, cropSz)
	whiteImage:Destroy()
	blackImage:Destroy()

	local pixelCount = cropSz.X * cropSz.Y
	local out = buffer.create(pixelCount * 4)

	for i = 0, pixelCount - 1 do
		local byteOffset = i * 4
		local whiteR = buffer.readu8(whiteBuf, byteOffset)
		local whiteG = buffer.readu8(whiteBuf, byteOffset + 1)
		local whiteB = buffer.readu8(whiteBuf, byteOffset + 2)
		local blackR = buffer.readu8(blackBuf, byteOffset)
		local blackG = buffer.readu8(blackBuf, byteOffset + 1)
		local blackB = buffer.readu8(blackBuf, byteOffset + 2)

		local alpha = 255 - math.round(((whiteR - blackR) + (whiteG - blackG) + (whiteB - blackB)) / 3)
		local outR, outG, outB

		if alpha > Constants.MIN_VISIBLE_ALPHA then
			local alphaNorm = alpha / 255
			outR = math.round(math.clamp(blackR / alphaNorm, 0, 255))
			outG = math.round(math.clamp(blackG / alphaNorm, 0, 255))
			outB = math.round(math.clamp(blackB / alphaNorm, 0, 255))
		else
			outR, outG, outB = 0, 0, 0
		end

		buffer.writeu8(out, byteOffset, outR)
		buffer.writeu8(out, byteOffset + 1, outG)
		buffer.writeu8(out, byteOffset + 2, outB)
		buffer.writeu8(out, byteOffset + 3, alpha)
	end

	return out, cropSz.X, cropSz.Y, nil
end

local function compositeBackground(buf: buffer, w: number, h: number, bgColor: Color3): buffer
	local bgR = math.floor(bgColor.R * 255 + 0.5)
	local bgG = math.floor(bgColor.G * 255 + 0.5)
	local bgB = math.floor(bgColor.B * 255 + 0.5)
	local total = w * h

	for i = 0, total - 1 do
		local o = i * 4
		local a = buffer.readu8(buf, o + 3) / 255
		buffer.writeu8(buf, o, math.floor(buffer.readu8(buf, o) * a + bgR * (1 - a) + 0.5))
		buffer.writeu8(buf, o + 1, math.floor(buffer.readu8(buf, o + 1) * a + bgG * (1 - a) + 0.5))
		buffer.writeu8(buf, o + 2, math.floor(buffer.readu8(buf, o + 2) * a + bgB * (1 - a) + 0.5))
		buffer.writeu8(buf, o + 3, 255)
	end

	return buf
end

local function resizeImage(ei: EditableImage, w: number, h: number, target: number): EditableImage
	if target <= 0 or (w == target and h == target) then
		return ei
	end

	local scaledEI = AssetService:CreateEditableImage({ Size = Vector2.new(target, target) })
	local okDraw = pcall(function()
		scaledEI:DrawImageTransformed(Vector2.new(target / 2, target / 2), Vector2.new(target / w, target / h), 0, ei)
	end)

	if okDraw then
		ei:Destroy()
		return scaledEI
	else
		scaledEI:Destroy()
		return ei
	end
end

local function renderOne(model: Instance, settings: RenderSettings)
	return Promise.new(function(resolve, reject)
		local okScale, scaleOrErr = getRenderScale():await()
		if not okScale then
			reject("renderOne: failed to get render scale: " .. tostring(scaleOrErr))
			return
		end
		local scale = scaleOrErr

		local maxPx = Constants.CAPTURE_MAX_DIMENSION
		if settings.exportSize > 0 then
			maxPx = math.min(settings.exportSize, Constants.CAPTURE_MAX_DIMENSION)
		end
		local capSize = math.floor(maxPx / math.max(scale.X, scale.Y))

		local vp, err = createCaptureViewport(model, settings, capSize)
		if not vp then
			reject("renderOne: failed to create capture viewport: " .. tostring(err))
			return
		end

		local bounds = getBoundsSnapshot(vp.modelClone)
		setupAnimation(vp.modelClone, vp.viewport, settings)
		applyCamera(vp.camera, vp.modelClone, {
			yaw = settings.yaw,
			pitch = settings.pitch,
			roll = settings.roll,
			fov = settings.fov,
			cameraDistance = settings.cameraDistance,
			offsetX = settings.cameraOffsetX or 0,
			offsetY = settings.cameraOffsetY or 0,
			offsetZ = settings.cameraOffsetZ or 0,
		}, bounds)

		task.wait(Constants.POLL_INTERVAL)

		local absPos = vp.viewport.AbsolutePosition
		local cropPos =
			Vector2.new(math.max(1, math.floor(absPos.X * scale.X)), math.max(1, math.floor(absPos.Y * scale.Y)))
		local cropSz =
			Vector2.new(math.min(math.floor(capSize * scale.X), maxPx), math.min(math.floor(capSize * scale.Y), maxPx))

		local rgba, w, h, errAlpha = extractAlpha(vp.bgFrame, vp.viewport, cropPos, cropSz)
		vp.gui:Destroy()

		if not rgba then
			reject("renderOne: failed to extract alpha: " .. tostring(errAlpha))
			return
		end

		rgba = postProcess.applyImageEffects(rgba, w, h, {
			innerShadow = settings.innerShadow,
			outline = settings.outline,
			dropShadow = settings.dropShadow,
			chromaticAberration = settings.chromaticAberration,
			outerGlow = settings.outerGlow,
		})

		if settings.bgMode == "color" or settings.bgMode == "custom" then
			rgba = compositeBackground(rgba, w, h, settings.bgColor)
		end

		local outEI = AssetService:CreateEditableImage({ Size = Vector2.new(w, h) })
		outEI:WritePixelsBuffer(Vector2.zero, Vector2.new(w, h), rgba)
		outEI = resizeImage(outEI, w, h, settings.exportSize)

		resolve(outEI)
	end)
end

return renderOne

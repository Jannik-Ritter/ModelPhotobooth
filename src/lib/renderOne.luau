local CoreGui = game:GetService("CoreGui")
local AssetService = game:GetService("AssetService")

local Packages = script.Parent.Parent.Parent.Packages
local Promise = require(Packages.promise)

local applyCamera = require(script.Parent.applyCamera)
local getBoundsSnapshot = require(script.Parent.viewportBounds)
local getRenderScale = require(script.Parent.getRenderScale)
local postProcess = require(script.Parent.postProcess)
local waitForAnimationTrackLength = require(script.Parent.Parent.utils.waitForAnimationTrackLength)
local snapScreenshot = require(script.Parent.Parent.utils.snapScreenshot)
local constants = require(script.Parent.Parent.constants)

type RenderSettings = {
	yaw: number,
	pitch: number,
	roll: number,
	fov: number,
	cameraDistance: number,
	cameraOffsetX: number,
	cameraOffsetY: number,
	cameraOffsetZ: number,
	outline: { enabled: boolean, color: Color3, thickness: number },
	dropShadow: { enabled: boolean, color: Color3, opacity: number, distance: number, blur: number, angle: number },
	innerShadow: { enabled: boolean, color: Color3, opacity: number, distance: number, blur: number, angle: number },
	outerGlow: { enabled: boolean, color: Color3, size: number, opacity: number, blur: number },
	chromaticAberration: { enabled: boolean, distance: number, opacity: number, angle: number },
	lighting: {
		lightColor: Color3,
		ambient: Color3,
		lightDirectionX: number,
		lightDirectionY: number,
		lightDirectionZ: number,
	},
	bgMode: string,
	bgColor: Color3,
	exportSize: number,
	animationId: string?,
	animationTimePosition: number?,
}

local INTERVAL = 0.05
local SNAP_TIMEOUT = 1 / 60 -- is enough for bg color to propagate
local POSE_RESOLVE_DT = 1 / 60
local POSE_STEP_COUNT = 3
local ANIMATION_LOAD_MAX_ATTEMPTS = 100

local function applyAnimationPoseAtTime(animator: Animator, track: AnimationTrack, timePosition: number)
	track:AdjustSpeed(0)
	track.TimePosition = timePosition
	animator:StepAnimations(POSE_RESOLVE_DT)
	track.TimePosition = timePosition
end

local function renderOne(model: Instance, settings: RenderSettings)
	return Promise.new(function(resolve, reject)
		local okScale, scaleOrErr = getRenderScale():await()
		if not okScale then
			reject(scaleOrErr)
			return
		end
		local scale = scaleOrErr
		-- When a fixed export size is set, cap capture + effects
		local maxPx = constants.CAPTURE_MAX_DIMENSION
		if settings.exportSize > 0 then
			maxPx = math.min(settings.exportSize, constants.CAPTURE_MAX_DIMENSION)
		end
		local CAPSIZE = math.floor(maxPx / math.max(scale.X, scale.Y))

		local tmpGui = Instance.new("ScreenGui")
		tmpGui.Name = "_MPhotoCapture"
		tmpGui.ResetOnSpawn = false
		tmpGui.DisplayOrder = 9999
		tmpGui.IgnoreGuiInset = true
		tmpGui.Parent = CoreGui

		local bgFr = Instance.new("Frame")
		bgFr.Size = UDim2.fromScale(1, 1)
		bgFr.BorderSizePixel = 0
		bgFr.Parent = tmpGui

		local tmpVP = Instance.new("ViewportFrame")
		tmpVP.Size = UDim2.fromOffset(CAPSIZE, CAPSIZE)
		tmpVP.Position = UDim2.new(0.5, -CAPSIZE / 2, 0.5, -CAPSIZE / 2)
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
			reject("failed to clone model")
			return
		end

		-- Bounds snapshot at rest pose to match PreviewViewport (bounds are computed at clone time
		-- before animation is set up, so camera distance is consistent between preview and render).
		local bounds = getBoundsSnapshot(tmpClone)

		-- Pose animation if specified (requires WorldModel + manual StepAnimations)
		if settings.animationId and settings.animationId ~= "" then
			local wm = Instance.new("WorldModel")
			wm.Parent = tmpVP
			tmpClone.Parent = wm

			local animator
			local humanoid = tmpClone:FindFirstChildWhichIsA("Humanoid")
			local animController = tmpClone:FindFirstChildWhichIsA("AnimationController")
			if humanoid then
				animator = humanoid:FindFirstChildWhichIsA("Animator")
				if not animator then
					animator = Instance.new("Animator")
					animator.Parent = humanoid
				end
			else
				if not animController then
					animController = Instance.new("AnimationController")
					animController.Parent = tmpClone
				end
				animator = animController:FindFirstChildWhichIsA("Animator")
				if not animator then
					animator = Instance.new("Animator")
					animator.Parent = animController
				end
			end

			local animObj = Instance.new("Animation")
			animObj.AnimationId = settings.animationId
			local track
			local loadOk = pcall(function()
				track = animator:LoadAnimation(animObj)
			end)
			animObj:Destroy()
			if loadOk and track then
				-- Match PreviewViewport animation setup so posed bounds (and camera fit via getCF)
				-- are consistent between live preview and export renders.
				track.Priority = Enum.AnimationPriority.Action4
				track.Looped = true
				track:Play(0)

				local okLength = waitForAnimationTrackLength(track, ANIMATION_LOAD_MAX_ATTEMPTS):await()
				if okLength then
					-- Step multiple times to fully resolve the pose (blend weights, IK, etc.)
					for _ = 1, POSE_STEP_COUNT do
						applyAnimationPoseAtTime(animator, track, settings.animationTimePosition or 0)
					end
					task.wait(INTERVAL) -- let the pose settle
				end
			end
		end

		applyCamera(tmpCam, tmpClone, {
			yaw = settings.yaw,
			pitch = settings.pitch,
			roll = settings.roll,
			fov = settings.fov,
			cameraDistance = settings.cameraDistance,
			offsetX = settings.cameraOffsetX or 0,
			offsetY = settings.cameraOffsetY or 0,
			offsetZ = settings.cameraOffsetZ or 0,
		}, bounds)
		task.wait(INTERVAL)

		local vp = tmpVP.AbsolutePosition
		-- Clamp to >= 1: ReadPixelsBuffer requires position.X and position.Y > 0
		local cropPos = Vector2.new(math.max(1, math.floor(vp.X * scale.X)), math.max(1, math.floor(vp.Y * scale.Y)))
		local cropSz =
			Vector2.new(math.min(math.floor(CAPSIZE * scale.X), maxPx), math.min(math.floor(CAPSIZE * scale.Y), maxPx))

		local function snap(bg: Color3): (boolean, EditableImage?)
			bgFr.BackgroundColor3 = bg
			tmpVP.BackgroundColor3 = bg

			task.wait(SNAP_TIMEOUT)

			return snapScreenshot(1, 0.05):await()
		end

		local white, black
		local snapOk, snapErr = pcall(function()
			local okW, w = snap(Color3.new(1, 1, 1))
			if not okW then
				error(w)
			end
			white = w
			local okB, b = snap(Color3.new(0, 0, 0))
			if not okB then
				error(b)
			end
			black = b
		end)

		tmpGui:Destroy()

		if not snapOk then
			if white then
				white:Destroy()
			end
			if black then
				black:Destroy()
			end
			reject(snapErr)
			return
		end

		local wBuf = white:ReadPixelsBuffer(cropPos, cropSz)
		local bBuf = black:ReadPixelsBuffer(cropPos, cropSz)
		white:Destroy()
		black:Destroy()

		local px = cropSz.X * cropSz.Y
		local out = buffer.create(px * 4)

		for i = 0, px - 1 do
			local o = i * 4
			local wr, wg, wb = buffer.readu8(wBuf, o), buffer.readu8(wBuf, o + 1), buffer.readu8(wBuf, o + 2)
			local br, bg, bb = buffer.readu8(bBuf, o), buffer.readu8(bBuf, o + 1), buffer.readu8(bBuf, o + 2)
			-- white_ch - black_ch = 255*(1-alpha) per channel, always >= 0; no math.max needed
			local outA = 255 - math.floor(((wr - br) + (wg - bg) + (wb - bb)) / 3 + 0.5)
			local outR, outG, outB
			if outA > 2 then -- equivalent to a > ~0.008
				local a = outA / 255
				outR = math.floor(math.clamp(br / a, 0, 255) + 0.5)
				outG = math.floor(math.clamp(bg / a, 0, 255) + 0.5)
				outB = math.floor(math.clamp(bb / a, 0, 255) + 0.5)
			else
				outR, outG, outB = 0, 0, 0
			end
			buffer.writeu8(out, o, outR)
			buffer.writeu8(out, o + 1, outG)
			buffer.writeu8(out, o + 2, outB)
			buffer.writeu8(out, o + 3, outA)
		end

		local w, h = cropSz.X, cropSz.Y

		-- Raw transparent RGBA; alpha-dependent effects run before background composite
		out = postProcess.applyImageEffects(out, w, h, {
			innerShadow = settings.innerShadow,
			outline = settings.outline,
			dropShadow = settings.dropShadow,
			chromaticAberration = settings.chromaticAberration,
			outerGlow = settings.outerGlow,
		})

		-- Composite onto background color after effects so the alpha channel is intact
		-- while effects run (outer glow and drop shadow need it to find the model boundary)
		if settings.bgMode == "color" or settings.bgMode == "custom" then
			local bgR = math.floor(settings.bgColor.R * 255 + 0.5)
			local bgG = math.floor(settings.bgColor.G * 255 + 0.5)
			local bgB = math.floor(settings.bgColor.B * 255 + 0.5)
			local total = w * h
			for i = 0, total - 1 do
				local o = i * 4
				local a = buffer.readu8(out, o + 3) / 255
				buffer.writeu8(out, o, math.floor(buffer.readu8(out, o) * a + bgR * (1 - a) + 0.5))
				buffer.writeu8(out, o + 1, math.floor(buffer.readu8(out, o + 1) * a + bgG * (1 - a) + 0.5))
				buffer.writeu8(out, o + 2, math.floor(buffer.readu8(out, o + 2) * a + bgB * (1 - a) + 0.5))
				buffer.writeu8(out, o + 3, 255)
			end
		end

		local outEI = AssetService:CreateEditableImage({ Size = Vector2.new(w, h) })
		outEI:WritePixelsBuffer(Vector2.zero, Vector2.new(w, h), out)

		-- Final step only when output size still differs (e.g. 1024 preset vs 1020px capture cap, or
		-- rounding made crop non-square). Usually skipped when export size matched maxPx above.
		local target = settings.exportSize
		if target > 0 and (w ~= target or h ~= target) then
			local scaledEI = AssetService:CreateEditableImage({ Size = Vector2.new(target, target) })
			local okDraw = pcall(function()
				-- Pivot defaults to image center; place pivot at output center.
				scaledEI:DrawImageTransformed(
					Vector2.new(target / 2, target / 2),
					Vector2.new(target / w, target / h),
					0,
					outEI
				)
			end)
			if okDraw then
				outEI:Destroy()
				outEI = scaledEI
			else
				scaledEI:Destroy()
			end
		end

		resolve(outEI)
	end)
end

return renderOne

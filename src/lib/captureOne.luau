local CoreGui = game:GetService("CoreGui")
local AssetService = game:GetService("AssetService")
local CaptureService = game:GetService("CaptureService")

local getCF = require(script.Parent.getCF)
local getCaptureScale = require(script.Parent.getCaptureScale)
local postProcess = require(script.Parent.postProcess)

type CaptureSettings = {
	yaw: number,
	pitch: number,
	fov: number,
	outline: { enabled: boolean, color: Color3, thickness: number },
	dropShadow: { enabled: boolean, color: Color3, opacity: number, distance: number, blur: number },
	innerShadow: { enabled: boolean, color: Color3, opacity: number, distance: number, blur: number, angle: number },
	bgMode: string,
	bgColor: Color3,
	exportSize: number,
}

local INTERVAL = 0.05
local SNAP_TIMEOUT = 0.05

local function captureOne(model: Instance, settings: CaptureSettings): EditableImage?
	local scale = getCaptureScale()
	local CAPSIZE = math.floor(1020 / math.max(scale.X, scale.Y))

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
	tmpVP.Size = UDim2.new(0, CAPSIZE, 0, CAPSIZE)
	tmpVP.Position = UDim2.new(0.5, -CAPSIZE / 2, 0.5, -CAPSIZE / 2)
	tmpVP.BorderSizePixel = 0
	tmpVP.Ambient = Color3.fromRGB(160, 160, 160)
	tmpVP.LightDirection = Vector3.new(-1, -2, -1)
	tmpVP.LightColor = Color3.new(1, 1, 1)
	tmpVP.Parent = tmpGui

	local tmpCam = Instance.new("Camera")
	tmpCam.Parent = tmpVP
	tmpVP.CurrentCamera = tmpCam
	tmpCam.FieldOfView = math.max(settings.fov, 1)

	local tmpClone
	local ok = pcall(function()
		tmpClone = model:Clone()
		tmpClone.Parent = tmpVP
	end)
	if not ok or not tmpClone then
		tmpGui:Destroy()
		return nil
	end

	tmpCam.CFrame = getCF(tmpClone, settings.yaw, settings.pitch, settings.fov)
	task.wait(INTERVAL)

	local vp = tmpVP.AbsolutePosition
	local cropPos = Vector2.new(math.floor(vp.X * scale.X), math.floor(vp.Y * scale.Y))
	local cropSz =
		Vector2.new(math.min(math.floor(CAPSIZE * scale.X), 1020), math.min(math.floor(CAPSIZE * scale.Y), 1020))

	local function snap(bg: Color3): EditableImage?
		bgFr.BackgroundColor3 = bg
		tmpVP.BackgroundColor3 = bg

		task.wait(SNAP_TIMEOUT)

		local done, ei = false, nil :: EditableImage?
		CaptureService:CaptureScreenshot(function(content)
			local ok2, img = pcall(function()
				return AssetService:CreateEditableImageAsync(content)
			end)
			ei = ok2 and img or nil
			done = true
		end)
		local t = tick()
		while not done and tick() - t < 6 do
			task.wait(0.05)
		end
		return ei
	end

	local white = snap(Color3.new(1, 1, 1))
	local black = snap(Color3.new(0, 0, 0))
	tmpGui:Destroy()

	if not white or not black then
		if white then
			white:Destroy()
		end
		if black then
			black:Destroy()
		end
		return nil
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
		local a = (
			(1 - math.max(0, wr - br) / 255)
			+ (1 - math.max(0, wg - bg) / 255)
			+ (1 - math.max(0, wb - bb) / 255)
		) / 3
		local outA = math.floor(a * 255 + 0.5)
		local outR, outG, outB
		if a > 0.008 then
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

	-- Composite onto background color if not transparent
	if settings.bgMode == "color" then
		local bgR = math.floor(settings.bgColor.R * 255 + 0.5)
		local bgG = math.floor(settings.bgColor.G * 255 + 0.5)
		local bgB = math.floor(settings.bgColor.B * 255 + 0.5)
		for i = 0, px - 1 do
			local o = i * 4
			local a = buffer.readu8(out, o + 3) / 255
			buffer.writeu8(out, o, math.floor(buffer.readu8(out, o) * a + bgR * (1 - a) + 0.5))
			buffer.writeu8(out, o + 1, math.floor(buffer.readu8(out, o + 1) * a + bgG * (1 - a) + 0.5))
			buffer.writeu8(out, o + 2, math.floor(buffer.readu8(out, o + 2) * a + bgB * (1 - a) + 0.5))
			buffer.writeu8(out, o + 3, 255)
		end
	end

	local w, h = cropSz.X, cropSz.Y

	-- Apply effects in order: inner shadow → outline → drop shadow
	if settings.innerShadow.enabled then
		out = postProcess.applyInnerShadow(
			out,
			w,
			h,
			settings.innerShadow.color,
			settings.innerShadow.opacity,
			settings.innerShadow.distance,
			settings.innerShadow.blur,
			settings.innerShadow.angle
		)
	end
	if settings.outline.enabled and settings.outline.thickness > 0 then
		out = postProcess.applyOutline(out, w, h, settings.outline.color, settings.outline.thickness)
	end
	if settings.dropShadow.enabled then
		out = postProcess.applyDropShadow(
			out,
			w,
			h,
			settings.dropShadow.color,
			settings.dropShadow.opacity,
			settings.dropShadow.distance,
			settings.dropShadow.blur
		)
	end

	local outEI = AssetService:CreateEditableImage({ Size = Vector2.new(w, h) })
	outEI:WritePixelsBuffer(Vector2.zero, Vector2.new(w, h), out)

	if settings.exportSize > 0 then
		pcall(function()
			outEI:Resize(Vector2.new(settings.exportSize, settings.exportSize))
		end)
	end

	return outEI
end

return captureOne

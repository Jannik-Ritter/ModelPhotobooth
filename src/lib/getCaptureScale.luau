local CoreGui = game:GetService("CoreGui")
local AssetService = game:GetService("AssetService")
local CaptureService = game:GetService("CaptureService")

local _cached: Vector2? = nil

local function getCaptureScale(): Vector2
	if _cached then
		return _cached
	end
	local sg = Instance.new("ScreenGui")
	sg.IgnoreGuiInset = true
	sg.ResetOnSpawn = false
	local fr = Instance.new("Frame")
	fr.Size = UDim2.fromScale(1, 1)
	fr.Parent = sg
	sg.Parent = CoreGui
	task.wait(0.12)
	local guiSz = fr.AbsoluteSize
	sg:Destroy()
	local done, sx, sy = false, 1, 1
	CaptureService:CaptureScreenshot(function(content)
		local ok, ei = pcall(function()
			return AssetService:CreateEditableImageAsync(content)
		end)
		if ok and ei then
			sx = ei.Size.X / guiSz.X
			sy = ei.Size.Y / guiSz.Y
			ei:Destroy()
		end
		done = true
	end)
	local t = tick()
	while not done and tick() - t < 6 do
		task.wait(0.05)
	end
	_cached = Vector2.new(sx, sy)
	return _cached
end

return getCaptureScale

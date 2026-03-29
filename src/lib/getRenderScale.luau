local CoreGui = game:GetService("CoreGui")
local AssetService = game:GetService("AssetService")
local CaptureService = game:GetService("CaptureService")

local Packages = script.Parent.Parent.Parent.Packages
local Promise = require(Packages.promise)

local cached: Vector2?
local pendingPromise: any?

local function getRenderScale()
	if cached then
		return Promise.resolve(cached)
	end

	if pendingPromise then
		return pendingPromise
	end

	pendingPromise = Promise.new(function(resolve, reject)
		-- Measure GUI space using a throwaway ScreenGui
		local screenGui = Instance.new("ScreenGui")
		screenGui.IgnoreGuiInset = true

		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromScale(1, 1)
		frame.Parent = screenGui
		screenGui.Parent = CoreGui

		task.spawn(function()
			local deadline = os.clock() + 2
			while frame.AbsoluteSize.X == 0 and os.clock() < deadline do
				task.wait()
			end

			local guiSz = frame.AbsoluteSize
			if guiSz.X == 0 or guiSz.Y == 0 then
				screenGui:Destroy()
				reject("failed to measure capture scale")
				return
			end

			CaptureService:CaptureScreenshot(function(content)
				local ok, ei = pcall(AssetService.CreateEditableImageAsync, AssetService, content)
				if not ok or not ei then
					screenGui:Destroy()
					reject("failed to create editable image")
					return
				end

				local scale = Vector2.new(ei.Size.X / guiSz.X, ei.Size.Y / guiSz.Y)
				ei:Destroy()
				screenGui:Destroy()
				resolve(scale)
			end)
		end)
	end)
		:andThen(function(scale)
			cached = scale
			return scale
		end)
		:finally(function()
			pendingPromise = nil
		end)

	return pendingPromise
end

return getRenderScale

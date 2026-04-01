local AssetService = game:GetService("AssetService")
local CaptureService = game:GetService("CaptureService")

local Packages = script.Parent.Parent.Parent.Packages
local Promise = require(Packages.promise)

local DEFAULT_TIMEOUT = 6
local DEFAULT_INTERVAL = 0.05

type Promise<T> = typeof(Promise.new)

-- Captures a screenshot via CaptureService and converts it to an EditableImage
-- Resolves with the EditableImage, or rejects after 'timeout' seconds
return function(timeout: number?, interval: number?): Promise<EditableImage>
	local timeLimit = timeout or DEFAULT_TIMEOUT
	local step = interval or DEFAULT_INTERVAL

	return Promise.new(function(resolve, reject)
		local done = false
		local result: EditableImage?

		CaptureService:CaptureScreenshot(function(content)
			local ok, img = pcall(function()
				return AssetService:CreateEditableImageAsync(content)
			end)
			if ok and img then
				result = img
			end
			done = true
		end)

		local elapsed = 0
		while not done and elapsed < timeLimit do
			task.wait(step)
			elapsed += step
		end

		if result then
			resolve(result)
		else
			reject("screenshot failed")
		end
	end)
end

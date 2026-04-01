local Types = require(script.Parent.Parent.Types)
local Constants = require(script.Parent.Parent.Constants)

export type BoundsSnapshot = Types.BoundsSnapshot

local function getBoundsSnapshot(target: Instance): Types.BoundsSnapshot
	local cf = CFrame.new()
	local size = Constants.DEFAULT_BOUNDS_SIZE
	local ok, err = pcall(function()
		if target:IsA("Model") then
			cf, size = target:GetBoundingBox()
		else
			cf = (target :: BasePart).CFrame
			size = (target :: BasePart).Size
		end
	end)
	if not ok then
		warn("viewportBounds: failed to get bounds for", target, "-", err)
	end
	return {
		cf = cf,
		size = size,
	}
end

return getBoundsSnapshot

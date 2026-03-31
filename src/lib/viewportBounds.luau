export type BoundsSnapshot = {
	cf: CFrame,
	size: Vector3,
}

local function getBoundsSnapshot(target: Instance): BoundsSnapshot
	local cf = CFrame.new()
	local size = Vector3.new(4, 4, 4)
	pcall(function()
		if target:IsA("Model") then
			cf, size = target:GetBoundingBox()
		else
			cf = (target :: BasePart).CFrame
			size = (target :: BasePart).Size
		end
	end)
	return {
		cf = cf,
		size = size,
	}
end

return getBoundsSnapshot

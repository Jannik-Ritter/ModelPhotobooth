local Constants = require(script.Parent.Parent.Constants)

local function getCF(
	model: Instance,
	yaw: number,
	pitch: number,
	fov: number,
	distanceMultiplier: number?,
	roll: number?,
	offset: Vector3?,
	boundsCF: CFrame?,
	boundsSize: Vector3?
): CFrame
	local cf = boundsCF
	local sz = boundsSize
	if not cf or not sz then
		pcall(function()
			if model:IsA("Model") then
				cf, sz = model:GetBoundingBox()
			else
				cf = (model :: BasePart).CFrame
				sz = (model :: BasePart).Size
			end
		end)
	end
	cf = cf or CFrame.new()
	sz = sz or Constants.DEFAULT_BOUNDS_SIZE
	-- 1.18 adds ~18% padding so the model isn't cropped at the exact viewport edge.
	local d = (sz.Magnitude / 2 / math.tan(math.rad(math.max(fov, 0.5) / 2))) * Constants.BOUNDS_PADDING_FACTOR * (distanceMultiplier or 1)
	local rot = CFrame.fromEulerAnglesYXZ(0, math.rad(yaw), 0) * CFrame.fromEulerAnglesYXZ(math.rad(-pitch), 0, 0)
	local targetPos = cf.Position + (offset or Vector3.zero)
	local look = CFrame.lookAt(targetPos + rot * Vector3.new(0, 0, d), targetPos)
	local r = roll or 0
	return look * CFrame.Angles(0, 0, math.rad(r))
end

return getCF

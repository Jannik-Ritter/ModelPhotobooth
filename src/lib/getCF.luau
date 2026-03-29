local function getCF(model: Instance, yaw: number, pitch: number, fov: number, distanceMultiplier: number?, roll: number?, offset: Vector3?): CFrame
	local cf, sz
	pcall(function()
		if model:IsA("Model") then
			cf, sz = model:GetBoundingBox()
		else
			cf = (model :: BasePart).CFrame
			sz = (model :: BasePart).Size
		end
	end)
	cf = cf or CFrame.new()
	sz = sz or Vector3.new(4, 4, 4)
	local d = (sz.Magnitude / 2 / math.tan(math.rad(math.max(fov, 0.5) / 2))) * 1.18 * (distanceMultiplier or 1)
	local rot = CFrame.fromEulerAnglesYXZ(0, math.rad(yaw), 0) * CFrame.fromEulerAnglesYXZ(math.rad(-pitch), 0, 0)
	local targetPos = cf.Position + (offset or Vector3.zero)
	local look = CFrame.lookAt(targetPos + rot * Vector3.new(0, 0, d), targetPos)
	local r = roll or 0
	return look * CFrame.Angles(0, 0, math.rad(r))
end

return getCF

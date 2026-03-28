local function getCF(model: Instance, yaw: number, pitch: number, fov: number): CFrame
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
	local d = (sz.Magnitude / 2 / math.tan(math.rad(math.max(fov, 0.5) / 2))) * 1.18
	local rot = CFrame.fromEulerAnglesYXZ(0, math.rad(yaw), 0) * CFrame.fromEulerAnglesYXZ(math.rad(-pitch), 0, 0)
	return CFrame.lookAt(cf.Position + rot * Vector3.new(0, 0, d), cf.Position)
end

return getCF

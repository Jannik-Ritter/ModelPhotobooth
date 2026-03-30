local shallowMerge = require(script.Parent.Parent.lib.shallowMerge).merge

return function(state, action)
	local patch = { yaw = action.yaw, pitch = action.pitch, fov = action.fov }
	if action.roll ~= nil then
		patch.roll = action.roll
	end
	if action.resetOffset then
		patch.cameraOffsetX = 0
		patch.cameraOffsetY = 0
		patch.cameraOffsetZ = 0
	end
	return shallowMerge(state, patch)
end

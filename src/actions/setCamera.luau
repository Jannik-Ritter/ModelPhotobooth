local shallowMerge = require(script.Parent.Parent.lib.shallowMerge).merge
local Constants = require(script.Parent.Parent.Constants)

return function(state, action)
	local patch = {
		yaw = action.yaw,
		pitch = math.clamp(action.pitch, Constants.CAMERA_PITCH_MIN, Constants.CAMERA_PITCH_MAX),
		fov = action.fov,
	}
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

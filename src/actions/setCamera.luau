local shallowMerge = require(script.Parent.Parent.lib.shallowMerge)

return function(state, action)
	local patch = { yaw = action.yaw, pitch = action.pitch, fov = action.fov }
	if action.roll ~= nil then
		patch.roll = action.roll
	end
	return shallowMerge(state, patch)
end

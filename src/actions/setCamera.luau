local shallowMerge = require(script.Parent.Parent.lib.shallowMerge)

return function(state, action)
	return shallowMerge(state, { yaw = action.yaw, pitch = action.pitch, fov = action.fov })
end

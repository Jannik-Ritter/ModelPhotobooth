local shallowMerge = require(script.Parent.Parent.lib.shallowMerge)

return function(state, action)
	return shallowMerge(state, {
		cameraOffsetX = action.x,
		cameraOffsetY = action.y,
		cameraOffsetZ = action.z,
	})
end

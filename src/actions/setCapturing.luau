local shallowMerge = require(script.Parent.Parent.lib.shallowMerge)

return function(state, action)
	return shallowMerge(state, {
		capturing = action.capturing,
		captureProgress = action.progress or state.captureProgress,
	})
end

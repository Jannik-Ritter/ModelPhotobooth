local shallowMerge = require(script.Parent.Parent.lib.shallowMerge).merge

return function(state, action)
	return shallowMerge(state, { cameraDistance = action.value })
end

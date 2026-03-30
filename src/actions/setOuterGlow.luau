local shallowMerge = require(script.Parent.Parent.lib.shallowMerge).merge

return function(state, action)
	return shallowMerge(state, { outerGlow = shallowMerge(state.outerGlow, action.value) })
end

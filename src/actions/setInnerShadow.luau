local shallowMerge = require(script.Parent.Parent.lib.shallowMerge)

return function(state, action)
	return shallowMerge(state, { innerShadow = shallowMerge(state.innerShadow, action.value) })
end

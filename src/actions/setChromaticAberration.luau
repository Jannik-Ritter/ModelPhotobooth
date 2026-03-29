local shallowMerge = require(script.Parent.Parent.lib.shallowMerge)

return function(state, action)
	return shallowMerge(state, { chromaticAberration = shallowMerge(state.chromaticAberration, action.value) })
end

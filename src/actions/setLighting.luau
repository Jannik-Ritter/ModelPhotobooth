local shallowMerge = require(script.Parent.Parent.lib.shallowMerge).merge

return function(state, action)
	return shallowMerge(state, { lighting = shallowMerge(state.lighting, action.value) })
end

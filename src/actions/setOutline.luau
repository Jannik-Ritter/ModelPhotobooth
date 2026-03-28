local shallowMerge = require(script.Parent.Parent.lib.shallowMerge)

return function(state, action)
	return shallowMerge(state, { outline = shallowMerge(state.outline, action.value) })
end

local shallowMerge = require(script.Parent.Parent.lib.shallowMerge).merge

return function(state, action)
	return shallowMerge(state, { outline = shallowMerge(state.outline, action.value) })
end

local shallowMerge = require(script.Parent.Parent.lib.shallowMerge)

return function(state, action)
	local newSections = table.clone(state.collapsedSections)
	newSections[action.value] = not newSections[action.value]
	return shallowMerge(state, { collapsedSections = newSections })
end

local shallowMerge = require(script.Parent.Parent.lib.shallowMerge).merge
local Constants = require(script.Parent.Parent.Constants)

return function(state, action)
	local newHistory = table.clone(state.renderHistory)
	table.insert(newHistory, 1, {
		image = action.image,
		modelName = action.modelName,
		modelIndex = action.modelIndex,
	})
	while #newHistory > Constants.MAX_RENDER_HISTORY do
		table.remove(newHistory)
	end
	return shallowMerge(state, { renderHistory = newHistory })
end

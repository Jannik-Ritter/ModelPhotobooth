local shallowMerge = require(script.Parent.Parent.lib.shallowMerge).merge

return function(state, action)
	return shallowMerge(state, {
		rendering = action.rendering,
		renderProgress = action.progress or state.renderProgress,
		renderTotal = if action.total ~= nil then action.total else state.renderTotal,
	})
end

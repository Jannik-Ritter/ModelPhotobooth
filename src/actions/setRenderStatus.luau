local shallowMerge = require(script.Parent.Parent.lib.shallowMerge).merge

return function(state, action)
	local newModels = table.clone(state.models)
	local entry = newModels[action.index]
	if entry then
		newModels[action.index] = shallowMerge(entry, {
			status = action.status,
			image = if action.image ~= nil then action.image else entry.image,
		})
	end
	return shallowMerge(state, { models = newModels })
end

local M = require(script.Parent.Parent.lib.shallowMerge)

return function(state, action)
	return M.merge(state, {
		previewImage = if action.image == nil then M.CLEAR else action.image,
		previewTitle = if action.title == nil then M.CLEAR else action.title,
		previewModelIndex = if action.index == nil then M.CLEAR else action.index,
	})
end

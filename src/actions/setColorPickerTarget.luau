local M = require(script.Parent.Parent.lib.shallowMerge)

return function(state, action)
	return M.merge(state, {
		colorPickerTarget = if action.value == nil then M.CLEAR else action.value,
	})
end

local M = require(script.Parent.Parent.lib.shallowMerge)

-- Returns a reducer handler that sets state[key] = action.value.
-- When action.value is nil the key is cleared via the CLEAR sentinel.
return function(key: string)
	return function(state, action)
		return M.merge(state, { [key] = if action.value == nil then M.CLEAR else action.value })
	end
end

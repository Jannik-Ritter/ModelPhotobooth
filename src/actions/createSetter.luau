local shallowMerge = require(script.Parent.Parent.lib.shallowMerge)

-- Returns a reducer handler that sets state[key] = action.value
return function(key: string)
	return function(state, action)
		return shallowMerge(state, { [key] = action.value })
	end
end

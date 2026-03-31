local shallowMerge = require(script.Parent.Parent.lib.shallowMerge).merge

-- Merges action.value into state[fieldName] (both are tables).
return function(fieldName: string)
	return function(state, action)
		return shallowMerge(state, {
			[fieldName] = shallowMerge(state[fieldName], action.value),
		})
	end
end

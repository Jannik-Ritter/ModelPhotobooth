return function(state, action)
	local new = table.clone(state)
	new.nameInputModal = action.value
	return new
end

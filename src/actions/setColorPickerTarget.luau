return function(state, action)
	local new = table.clone(state)
	new.colorPickerTarget = action.value
	return new
end

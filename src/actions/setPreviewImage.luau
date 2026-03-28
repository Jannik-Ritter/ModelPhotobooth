return function(state, action)
	local new = table.clone(state)
	new.previewImage = action.image
	new.previewTitle = action.title
	return new
end

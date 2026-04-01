local Store = require(script.Parent.Parent.Store)

return function(state: Store.AppState)
	local prevRenderedIndex = nil
	local nextRenderedIndex = nil
	local previewIdx = state.previewModelIndex
	if previewIdx then
		for i = previewIdx - 1, 1, -1 do
			if state.models[i] and state.models[i].image then
				prevRenderedIndex = i
				break
			end
		end
		for i = previewIdx + 1, #state.models do
			if state.models[i] and state.models[i].image then
				nextRenderedIndex = i
				break
			end
		end
	end

	local prevHistoryIndex = nil
	local nextHistoryIndex = nil
	local previewHistIdx = state.previewHistoryIndex
	if previewHistIdx then
		if previewHistIdx > 1 then
			prevHistoryIndex = previewHistIdx - 1
		end
		if previewHistIdx < #state.renderHistory then
			nextHistoryIndex = previewHistIdx + 1
		end
	end

	local previewFromHistory = state.previewHistoryIndex ~= nil

	return {
		prevRenderedIndex = prevRenderedIndex,
		nextRenderedIndex = nextRenderedIndex,
		prevHistoryIndex = prevHistoryIndex,
		nextHistoryIndex = nextHistoryIndex,
		previewFromHistory = previewFromHistory,
	}
end

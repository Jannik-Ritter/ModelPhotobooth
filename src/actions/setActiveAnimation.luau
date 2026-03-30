local M = require(script.Parent.Parent.lib.shallowMerge)

-- Selects an animation; playback state is preserved when switching tracks.
-- Clearing the selection also stops playback so the rig is left idle.
return function(state, action)
	local deselected = action.value == nil
	return M.merge(state, {
		activeAnimationIndex = if deselected then M.CLEAR else action.value,
		animationPlaying = if deselected then false else state.animationPlaying,
		animationTimePosition = 0,
		animationLength = 0,
	})
end

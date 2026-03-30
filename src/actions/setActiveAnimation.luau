local M = require(script.Parent.Parent.lib.shallowMerge)

-- Selects an animation; playback state (playing vs paused) is unchanged.
-- action.value may be nil (deselect), handled via CLEAR sentinel.
return function(state, action)
	return M.merge(state, {
		activeAnimationIndex = if action.value == nil then M.CLEAR else action.value,
		animationTimePosition = 0,
		animationLength = 0,
	})
end

local shallowMerge = require(script.Parent.Parent.lib.shallowMerge)

-- Selects an animation; playback state (playing vs paused) is unchanged
return function(state, action)
	return shallowMerge(state, {
		activeAnimationIndex = action.value,
		animationTimePosition = 0,
		animationLength = 0,
	})
end

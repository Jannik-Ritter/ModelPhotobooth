local shallowMerge = require(script.Parent.Parent.lib.shallowMerge)

-- Selects an animation and resets playback state
return function(state, action)
	return shallowMerge(state, {
		activeAnimationIndex = action.value,
		animationPlaying = false,
		animationTimePosition = 0,
		animationLength = 0,
	})
end

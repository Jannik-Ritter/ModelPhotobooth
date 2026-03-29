local shallowMerge = require(script.Parent.Parent.lib.shallowMerge)

-- Resets all animation state when the animation list changes (e.g. new model selected)
return function(state, action)
	return shallowMerge(state, {
		animations = action.value,
		activeAnimationIndex = nil,
		animationPlaying = false,
		animationTimePosition = 0,
		animationLength = 0,
	})
end

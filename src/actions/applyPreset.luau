local shallowMerge = require(script.Parent.Parent.lib.shallowMerge)

return function(state, action)
	local preset = action.value
	return shallowMerge(state, {
		yaw = preset.yaw,
		pitch = preset.pitch,
		fov = preset.fov,
		cameraDistance = preset.cameraDistance,
		bgMode = preset.bgMode,
		bgColor = preset.bgColor,
		exportSize = preset.exportSize,
		outline = preset.outline,
		dropShadow = preset.dropShadow,
		innerShadow = preset.innerShadow,
		outerGlow = preset.outerGlow,
		chromaticAberration = preset.chromaticAberration,
	})
end

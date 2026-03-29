local shallowMerge = require(script.Parent.Parent.lib.shallowMerge)

return function(state, action)
	local preset = action.value
	return shallowMerge(state, {
		yaw = preset.yaw,
		pitch = preset.pitch,
		roll = preset.roll or 0,
		fov = preset.fov,
		cameraDistance = preset.cameraDistance,
		cameraOffsetX = preset.cameraOffsetX or 0,
		cameraOffsetY = preset.cameraOffsetY or 0,
		cameraOffsetZ = preset.cameraOffsetZ or 0,
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

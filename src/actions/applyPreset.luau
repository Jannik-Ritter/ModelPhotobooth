local shallowMerge = require(script.Parent.Parent.lib.shallowMerge).merge
local Constants = require(script.Parent.Parent.Constants)

return function(state, action)
	local preset = action.value
	return shallowMerge(state, {
		yaw = preset.yaw,
		pitch = math.clamp(preset.pitch, Constants.CAMERA_PITCH_MIN, Constants.CAMERA_PITCH_MAX),
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
		lighting = preset.lighting or {
			lightColor = Color3.new(1, 1, 1),
			ambient = Color3.fromRGB(160, 160, 160),
			lightDirectionX = -1,
			lightDirectionY = -2,
			lightDirectionZ = -1,
		},
	})
end

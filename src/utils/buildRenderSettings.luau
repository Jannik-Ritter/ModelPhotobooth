-- Pure function: builds the renderSettings table from app state.
local Store = require(script.Parent.Parent.Store)

return function(state: Store.AppState)
	return {
		yaw = state.yaw,
		pitch = state.pitch,
		roll = state.roll,
		fov = state.fov,
		cameraDistance = state.cameraDistance,
		cameraOffsetX = state.cameraOffsetX,
		cameraOffsetY = state.cameraOffsetY,
		cameraOffsetZ = state.cameraOffsetZ,
		outline = state.outline,
		dropShadow = state.dropShadow,
		innerShadow = state.innerShadow,
		outerGlow = state.outerGlow,
		chromaticAberration = state.chromaticAberration,
		lighting = state.lighting,
		bgMode = state.bgMode,
		bgColor = state.bgColor,
		exportSize = state.exportSize,
		animationId = if state.activeAnimationIndex
			then state.animations[state.activeAnimationIndex]
				and state.animations[state.activeAnimationIndex].animationId
			else nil,
		animationTimePosition = state.animationTimePosition,
	}
end

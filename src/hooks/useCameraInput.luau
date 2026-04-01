local Store = require(script.Parent.Parent.Store)
local Constants = require(script.Parent.Parent.Constants)

return function(state: Store.AppState, dispatch: (any) -> (), isCtrlDown: () -> boolean)
	local function onTrackball(dYaw: number, dPitch: number)
		local nextPitch = math.clamp(state.pitch + dPitch, Constants.CAMERA_PITCH_MIN, Constants.CAMERA_PITCH_MAX)
		dispatch({
			type = Store.ACTIONS.SET_CAMERA,
			yaw = state.yaw + dYaw,
			pitch = nextPitch,
			fov = state.fov,
		})
	end

	local function onTranslate(dx: number, dy: number, dz: number)
		dispatch({
			type = Store.ACTIONS.SET_CAMERA_OFFSET,
			x = math.clamp(state.cameraOffsetX + dx, Constants.CAMERA_OFFSET_MIN, Constants.CAMERA_OFFSET_MAX),
			y = math.clamp(state.cameraOffsetY + dy, Constants.CAMERA_OFFSET_MIN, Constants.CAMERA_OFFSET_MAX),
			z = math.clamp(state.cameraOffsetZ + dz, Constants.CAMERA_OFFSET_MIN, Constants.CAMERA_OFFSET_MAX),
		})
	end

	local function onScroll(direction: number)
		if isCtrlDown() then
			local newFov =
				math.clamp(state.fov + direction * Constants.FOV_SCROLL_STEP, Constants.FOV_MIN, Constants.FOV_MAX)
			dispatch({ type = Store.ACTIONS.SET_FOV, value = newFov })
		else
			local newDistance = math.clamp(
				state.cameraDistance - direction * Constants.CAMERA_DISTANCE_SCROLL_STEP,
				Constants.CAMERA_DISTANCE_MIN,
				Constants.CAMERA_DISTANCE_MAX
			)
			dispatch({ type = Store.ACTIONS.SET_CAMERA_DISTANCE, value = newDistance })
		end
	end

	local function onResetCamera()
		dispatch({
			type = Store.ACTIONS.SET_CAMERA,
			yaw = Store.DEFAULT_STATE.yaw,
			pitch = Store.DEFAULT_STATE.pitch,
			fov = Store.DEFAULT_STATE.fov,
			roll = 0,
			resetOffset = true,
		})
		dispatch({ type = Store.ACTIONS.SET_CAMERA_DISTANCE, value = Store.DEFAULT_STATE.cameraDistance })
	end

	return {
		onTrackball = onTrackball,
		onTranslate = onTranslate,
		onScroll = onScroll,
		onResetCamera = onResetCamera,
	}
end

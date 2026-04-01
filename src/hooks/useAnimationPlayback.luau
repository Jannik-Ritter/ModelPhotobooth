local RunService = game:GetService("RunService")

local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local Store = require(script.Parent.Parent.Store)
local applyCamera = require(script.Parent.Parent.lib.applyCamera)
local animationHelpers = require(script.Parent.Parent.lib.animationHelpers)
local waitForAnimationTrackLength = require(script.Parent.Parent.utils.waitForAnimationTrackLength)

local applyAnimationPoseAtTime = animationHelpers.applyAnimationPoseAtTime
local getOrCreateAnimator = animationHelpers.getOrCreateAnimator

local function stopAndDestroyTrack(trackRef: { current: AnimationTrack? }, animator: Animator?)
	local track = trackRef.current
	if track then
		track:Stop(0)
		track:Destroy()
		trackRef.current = nil
		if animator then
			animator:StepAnimations(0)
		end
	end
end

-- Maps camera state fields to the shape applyCamera expects.
local function toCameraParams(cs)
	return {
		yaw = cs.yaw,
		pitch = cs.pitch,
		roll = cs.roll,
		fov = cs.fov,
		cameraDistance = cs.distance,
		offsetX = cs.offsetX,
		offsetY = cs.offsetY,
		offsetZ = cs.offsetZ,
	}
end

type Refs = {
	cloneRef: { current: Instance? },
	camRef: { current: Camera? },
	boundsRef: { current: any },
	cameraStateRef: { current: any },
}

-- Manages animation track loading, scrubbing, and real-time playback for the preview viewport.
-- Owns trackRef and animatorRef internally.
return function(state: Store.AppState, dispatch: (any) -> (), activeInstance: Instance?, refs: Refs)
	local trackRef = React.useRef(nil :: AnimationTrack?)
	local animatorRef = React.useRef(nil :: Animator?)

	-- Load / switch animation track when the active animation index or model changes.
	React.useEffect(function()
		local clone = refs.cloneRef.current
		if not clone then
			return
		end

		stopAndDestroyTrack(trackRef, animatorRef.current)

		if not state.activeAnimationIndex then
			animatorRef.current = nil
			return
		end

		local animInfo = state.animations[state.activeAnimationIndex]
		if not animInfo then
			animatorRef.current = nil
			return
		end

		local animator = getOrCreateAnimator(clone)
		if not animator then
			animatorRef.current = nil
			return
		end
		animatorRef.current = animator

		local anim = Instance.new("Animation")
		anim.AnimationId = animInfo.animationId
		local track: AnimationTrack?
		local loadOk = pcall(function()
			track = animator:LoadAnimation(anim)
		end)
		anim:Destroy()
		if not loadOk or not track then
			return
		end

		track.Priority = Enum.AnimationPriority.Action4
		track.Looped = true
		track:Play(0)
		trackRef.current = track

		-- Wait for animation to load before applying pose (StepAnimations needs loaded data)
		local lengthPromise = waitForAnimationTrackLength(track)
		lengthPromise
			:andThen(function()
				if trackRef.current ~= track then
					return
				end
				dispatch({ type = Store.ACTIONS.SET_ANIMATION_LENGTH, value = track.Length })
				if not state.animationPlaying then
					applyAnimationPoseAtTime(animator, track, state.animationTimePosition)
				else
					track.TimePosition = state.animationTimePosition
				end
				if refs.camRef.current and refs.cloneRef.current then
					applyCamera(
						refs.camRef.current,
						refs.cloneRef.current,
						toCameraParams(refs.cameraStateRef.current),
						refs.boundsRef.current
					)
				end
			end)
			:catch(function(err)
				print(err)
			end)

		return function()
			if trackRef.current == track then
				track:Stop(0)
				track:Destroy()
				trackRef.current = nil
				local anim = animatorRef.current
				if anim then
					anim:StepAnimations(0)
				end
			end
		end
	end, { state.activeAnimationIndex, activeInstance } :: { any })

	-- Scrub when paused (external time position change from scrubber).
	React.useEffect(function()
		local track = trackRef.current
		local animator = animatorRef.current
		if not track or not animator or state.animationPlaying then
			return
		end
		applyAnimationPoseAtTime(animator, track, state.animationTimePosition)
		if refs.camRef.current and refs.cloneRef.current then
			applyCamera(
				refs.camRef.current,
				refs.cloneRef.current,
				toCameraParams(refs.cameraStateRef.current),
				refs.boundsRef.current
			)
		end
	end, { state.animationTimePosition, state.animationPlaying, state.activeAnimationIndex })

	-- Apply pose when track becomes available (handles "just loaded" case when paused).
	React.useEffect(function()
		local track = trackRef.current
		local animator = animatorRef.current
		if not track or not animator or state.animationPlaying then
			return
		end
		applyAnimationPoseAtTime(animator, track, state.animationTimePosition)
		if refs.camRef.current and refs.cloneRef.current then
			applyCamera(
				refs.camRef.current,
				refs.cloneRef.current,
				toCameraParams(refs.cameraStateRef.current),
				refs.boundsRef.current
			)
		end
	end, { state.activeAnimationIndex })

	-- Manual playback via StepAnimations during Heartbeat.
	React.useEffect(function()
		if not state.animationPlaying then
			return
		end
		local track = trackRef.current
		local animator = animatorRef.current
		if not track or not animator then
			return
		end
		track:AdjustSpeed(1)
		local conn = RunService.Heartbeat:Connect(function(dt)
			animator:StepAnimations(dt)
			if refs.camRef.current and refs.cloneRef.current then
				applyCamera(
					refs.camRef.current,
					refs.cloneRef.current,
					toCameraParams(refs.cameraStateRef.current),
					refs.boundsRef.current
				)
			end
			dispatch({ type = Store.ACTIONS.SET_ANIMATION_TIME, value = track.TimePosition })
		end)
		return function()
			conn:Disconnect()
		end
	end, { state.animationPlaying, state.activeAnimationIndex, activeInstance })
end

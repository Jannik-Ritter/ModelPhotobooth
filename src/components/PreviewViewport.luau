local RunService = game:GetService("RunService")

local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local getCF = require(script.Parent.Parent.lib.getCF)
local useTrackball = require(script.Parent.Parent.hooks.useTrackball)
local AnimationPanel = require(script.Parent.AnimationPanel)

local e = React.createElement

local DEFAULT_VP_WIDTH = 400
local ROTATION_SENSITIVITY = 0.5

local CURSOR_ORBIT_HOVER = "rbxasset://SystemCursors/OpenHand"
local CURSOR_ORBIT_DRAG = "rbxasset://SystemCursors/ClosedHand"
local CURSOR_PAN = "rbxasset://SystemCursors/Cross"

-- StepAnimations(0) often fails to fully resolve the pose in a WorldModel (partial blend / low
-- effective weight). Real playback uses StepAnimations(dt) with dt > 0. For scrubbing we freeze
-- the track, step with a nominal frame, then snap TimePosition back if anything drifted.
local POSE_RESOLVE_DT = 1 / 60

local function applyAnimationPoseAtTime(animator: Animator, track: AnimationTrack, timePosition: number)
	track:AdjustSpeed(0)
	track.TimePosition = timePosition
	animator:StepAnimations(POSE_RESOLVE_DT)
	track.TimePosition = timePosition
end

-- Equivalent angle in (-180, 180] for display (rotation math uses unbounded degrees)
local function wrapSigned180(deg: number): number
	local x = (deg % 360 + 360) % 360
	if x > 180 then
		return x - 360
	end
	return x
end

type AnimationInfo = {
	name: string,
	animationId: string,
}

type Props = {
	entry: {
		instance: Instance,
		status: string,
		image: EditableImage?,
		isExported: boolean,
	}?,
	yaw: number,
	pitch: number,
	roll: number,
	fov: number,
	cameraDistance: number,
	offsetX: number,
	offsetY: number,
	offsetZ: number,
	onTrackball: (dYaw: number, dPitch: number) -> (),
	onTranslate: (dx: number, dy: number, dz: number) -> (),
	onScroll: (direction: number) -> (),
	onResetCamera: () -> (),
	isShiftDown: () -> boolean,
	shiftDown: boolean,
	-- Animation
	animations: { AnimationInfo },
	activeAnimationIndex: number?,
	animationPlaying: boolean,
	animationTimePosition: number,
	animationLength: number,
	onSelectAnimation: (index: number?) -> (),
	onSetPlaying: (playing: boolean) -> (),
	onSetTimePosition: (time: number) -> (),
	onSetLength: (length: number) -> (),
	lighting: {
		lightColor: Color3,
		ambient: Color3,
		lightDirectionX: number,
		lightDirectionY: number,
		lightDirectionZ: number,
	},
}

type CameraState = {
	yaw: number,
	pitch: number,
	roll: number,
	fov: number,
	distance: number,
	offsetX: number,
	offsetY: number,
	offsetZ: number,
}

type BoundsSnapshot = {
	cf: CFrame,
	size: Vector3,
}

local function toOffsetVector(state: CameraState): Vector3
	return Vector3.new(state.offsetX, state.offsetY, state.offsetZ)
end

local function getBoundsSnapshot(target: Instance): BoundsSnapshot
	local cf = CFrame.new()
	local size = Vector3.new(4, 4, 4)
	pcall(function()
		if target:IsA("Model") then
			cf, size = target:GetBoundingBox()
		else
			cf = (target :: BasePart).CFrame
			size = (target :: BasePart).Size
		end
	end)
	return {
		cf = cf,
		size = size,
	}
end

local function applyCamera(camera: Camera, target: Instance, state: CameraState, bounds: BoundsSnapshot?)
	camera.FieldOfView = math.max(state.fov, 1)
	camera.CFrame = getCF(
		target,
		state.yaw,
		state.pitch,
		state.fov,
		state.distance,
		state.roll,
		toOffsetVector(state),
		if bounds then bounds.cf else nil,
		if bounds then bounds.size else nil
	)
end

local function stopAndDestroyTrack(trackRef: { current: AnimationTrack? })
	local track = trackRef.current
	if track then
		track:Stop()
		track:Destroy()
		trackRef.current = nil
	end
end

local function getOrCreateAnimator(clone: Instance): Animator?
	local humanoid = clone:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		local animator = humanoid:FindFirstChildWhichIsA("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end
		return animator
	end

	local animController = clone:FindFirstChildWhichIsA("AnimationController")
	if not animController then
		animController = Instance.new("AnimationController")
		animController.Parent = clone
	end

	local animator = animController:FindFirstChildWhichIsA("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = animController
	end

	return animator
end

local function getCloneSizeMagnitude(clone: Instance): number
	local sizeMagnitude = 4 * math.sqrt(3)
	pcall(function()
		if clone:IsA("Model") then
			local _, size = clone:GetBoundingBox()
			sizeMagnitude = size.Magnitude
		else
			sizeMagnitude = (clone :: BasePart).Size.Magnitude
		end
	end)
	return sizeMagnitude
end

local function PreviewViewport(props: Props)
	local theme = StudioComponents.useTheme()
	local mouseIcon = StudioComponents.useMouseIcon()
	local pointerInViewport, setPointerInViewport = React.useState(false)
	local pointerInViewportRef = React.useRef(false)

	local vpRef = React.useRef(nil :: ViewportFrame?)
	local camRef = React.useRef(nil :: Camera?)
	local cloneRef = React.useRef(nil :: Instance?)
	local boundsRef = React.useRef(nil :: BoundsSnapshot?)
	local trackRef = React.useRef(nil :: AnimationTrack?)
	local animatorRef = React.useRef(nil :: Animator?)

	local cameraStateRef = React.useRef({
		yaw = props.yaw,
		pitch = props.pitch,
		roll = props.roll,
		fov = props.fov,
		distance = props.cameraDistance,
		offsetX = props.offsetX,
		offsetY = props.offsetY,
		offsetZ = props.offsetZ,
	} :: CameraState)

	-- Keep event handlers in sync with latest values without many tiny effects.
	cameraStateRef.current = {
		yaw = props.yaw,
		pitch = props.pitch,
		roll = props.roll,
		fov = props.fov,
		distance = props.cameraDistance,
		offsetX = props.offsetX,
		offsetY = props.offsetY,
		offsetZ = props.offsetZ,
	}

	local activeInstance = if props.entry then props.entry.instance else nil

	-- 1:1 capture region matches min(viewport W,H); dim letterbox/pillarbox (overlay inside ViewportFrame, below HUD).
	local overlaySize, setOverlaySize = React.useState(Vector2.new(0, 0))
	React.useEffect(function()
		local vp = vpRef.current
		if not vp then
			return
		end
		local function sync()
			setOverlaySize(vp.AbsoluteSize)
		end
		sync()
		local conn = vp:GetPropertyChangedSignal("AbsoluteSize"):Connect(sync)
		return function()
			conn:Disconnect()
		end
	end, {})

	-- Clone model into viewport (using WorldModel for animation support)
	React.useEffect(function()
		local vp = vpRef.current
		if not vp or not activeInstance then
			return
		end

		local camera = Instance.new("Camera")
		camera.Parent = vp
		vp.CurrentCamera = camera

		local worldModel = Instance.new("WorldModel")
		worldModel.Parent = vp

		local clone
		local ok = pcall(function()
			clone = activeInstance:Clone()
			clone.Parent = worldModel
		end)
		if not ok or not clone then
			camera:Destroy()
			worldModel:Destroy()
			return
		end

		camRef.current = camera
		cloneRef.current = clone
		boundsRef.current = getBoundsSnapshot(clone)
		applyCamera(camera, clone, cameraStateRef.current, boundsRef.current)

		return function()
			stopAndDestroyTrack(trackRef)
			animatorRef.current = nil
			camera:Destroy()
			worldModel:Destroy()
			camRef.current = nil
			cloneRef.current = nil
			boundsRef.current = nil
		end
	end, { activeInstance, props.activeAnimationIndex })

	-- Load animation track when active animation changes
	React.useEffect(function()
		local clone = cloneRef.current
		if not clone then
			return
		end

		stopAndDestroyTrack(trackRef)

		if not props.activeAnimationIndex then
			animatorRef.current = nil
			return
		end

		local animInfo = props.animations[props.activeAnimationIndex]
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

		applyAnimationPoseAtTime(animator, track, props.animationTimePosition)

		-- Re-apply camera after pose changes so the preview updates immediately. Camera fit uses
		-- cached pre-animation bounds for stability across preview and export.
		if camRef.current and cloneRef.current then
			applyCamera(camRef.current, cloneRef.current, cameraStateRef.current, boundsRef.current)
		end

		task.spawn(function()
			local attempts = 0
			while track.Length == 0 and attempts < 100 do
				task.wait(0.05)
				attempts += 1
			end
			if trackRef.current == track and track.Length > 0 then
				props.onSetLength(track.Length)
			end
		end)

		return function()
			if trackRef.current == track then
				track:Stop()
				track:Destroy()
				trackRef.current = nil
			end
		end
	end, { props.activeAnimationIndex, activeInstance } :: { any })

	-- Scrub when paused (external time position change from scrubber)
	React.useEffect(function()
		local track = trackRef.current
		local animator = animatorRef.current
		if not track or not animator or props.animationPlaying then
			return
		end

		applyAnimationPoseAtTime(animator, track, props.animationTimePosition)

		local camera = camRef.current
		local clone = cloneRef.current
		if camera and clone then
			applyCamera(camera, clone, cameraStateRef.current, boundsRef.current)
		end
	end, { props.animationTimePosition, props.animationPlaying, props.activeAnimationIndex })

	-- Manual playback via StepAnimations during Heartbeat
	React.useEffect(function()
		if not props.animationPlaying then
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
			local camera = camRef.current
			local clone = cloneRef.current
			if camera and clone then
				applyCamera(camera, clone, cameraStateRef.current, boundsRef.current)
			end
			props.onSetTimePosition(track.TimePosition)
		end)

		return function()
			conn:Disconnect()
		end
	end, { props.animationPlaying, props.activeAnimationIndex, activeInstance })

	-- Update camera when camera inputs change externally
	React.useEffect(
		function()
			local camera = camRef.current
			local clone = cloneRef.current
			if camera and clone then
				applyCamera(camera, clone, cameraStateRef.current, boundsRef.current)
			end
		end,
		{
			props.yaw,
			props.pitch,
			props.roll,
			props.fov,
			props.cameraDistance,
			props.offsetX,
			props.offsetY,
			props.offsetZ,
		} :: { any }
	)

	-- Trackball / translate
	local trackball = useTrackball(function(dx: number, dy: number)
		local camera = camRef.current
		local clone = cloneRef.current
		local state = cameraStateRef.current
		if not camera or not clone then
			return
		end

		if props.isShiftDown() then
			local vpWidth = if vpRef.current then vpRef.current.AbsoluteSize.X else DEFAULT_VP_WIDTH
			local scale = getCloneSizeMagnitude(clone) * 1.18 * state.distance / vpWidth
			local rot = CFrame.fromEulerAnglesYXZ(0, math.rad(state.yaw), 0)
				* CFrame.fromEulerAnglesYXZ(math.rad(-state.pitch), 0, 0)
			local right = rot * Vector3.new(1, 0, 0)
			local up = rot * Vector3.new(0, 1, 0)
			local delta = right * (-dx * scale) + up * (dy * scale)

			state.offsetX += delta.X
			state.offsetY += delta.Y
			state.offsetZ += delta.Z
			applyCamera(camera, clone, state, boundsRef.current)
			props.onTranslate(delta.X, delta.Y, delta.Z)
			return
		end

		local yawDelta = -dx * ROTATION_SENSITIVITY
		local pitchDelta = dy * ROTATION_SENSITIVITY
		state.yaw += yawDelta
		state.pitch += pitchDelta
		applyCamera(camera, clone, state, boundsRef.current)
		props.onTrackball(yawDelta, pitchDelta)
	end)

	local isDragging = trackball.isDragging

	-- plugin:GetMouse().Icon is global. Ref syncs on leave before React state so a late Heartbeat/effect
	-- cannot setIcon after clearIcon. shiftDown is real state from App so cursor updates when Shift toggles.
	local applyViewportCursor = React.useCallback(function()
		if not pointerInViewportRef.current then
			mouseIcon.clearIcon()
			return
		end
		local url = if props.shiftDown then CURSOR_PAN elseif isDragging then CURSOR_ORBIT_DRAG else CURSOR_ORBIT_HOVER
		mouseIcon.setIcon(url)
	end, { isDragging, props.shiftDown } :: { any })

	React.useEffect(function()
		applyViewportCursor()
	end, { pointerInViewport, isDragging, props.shiftDown, applyViewportCursor } :: { any })

	local emptyLabel = nil
	if not props.entry then
		emptyLabel = e(StudioComponents.Label, {
			Text = "Select a model in Explorer",
			Size = UDim2.fromScale(1, 1),
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 5,
		})
	end

	local readout = e(StudioComponents.DropShadowFrame, {
		Size = UDim2.fromOffset(120, 20),
		Position = UDim2.fromOffset(8, 8),
		AnchorPoint = Vector2.new(0, 0),
		ZIndex = 15,
	}, {
		label = e(StudioComponents.Label, {
			Text = string.format(
				"%.0f\u{00B0}  %.0f\u{00B0}  R%.0f\u{00B0}",
				wrapSigned180(props.yaw),
				wrapSigned180(props.pitch),
				wrapSigned180(props.roll)
			),
			Size = UDim2.fromScale(1, 1),
			TextXAlignment = Enum.TextXAlignment.Center,
		}),
	})

	local resetCameraBtn = e(StudioComponents.DropShadowFrame, {
		Size = UDim2.fromOffset(24, 20),
		Position = UDim2.new(1, -8, 0, 8),
		AnchorPoint = Vector2.new(1, 0),
		ZIndex = 15,
	}, {
		btn = e(StudioComponents.Button, {
			OnActivated = props.onResetCamera,
			Icon = {
				Image = "rbxassetid://114794754040951",
				Size = Vector2.new(16, 16),
				UseThemeColor = true,
			},
			Size = UDim2.fromScale(1, 1),
		}),
	})

	local animPanel = nil
	if #props.animations > 0 then
		animPanel = e(AnimationPanel, {
			animations = props.animations,
			activeAnimationIndex = props.activeAnimationIndex,
			playing = props.animationPlaying,
			timePosition = props.animationTimePosition,
			length = props.animationLength,
			onSelectAnimation = props.onSelectAnimation,
			onSetPlaying = props.onSetPlaying,
			onSetTimePosition = props.onSetTimePosition,
		})
	end

	local ow = overlaySize.X
	local oh = overlaySize.Y
	local aspectOverlay = nil
	if ow > 0 and oh > 0 then
		local side = math.min(ow, oh)
		if ow >= oh then
			local barW = (ow - side) / 2
			aspectOverlay = e("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Active = false,
				ZIndex = 2,
			}, {
				layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Top,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					Padding = UDim.new(0, 0),
				}),
				left = e("Frame", {
					LayoutOrder = 1,
					Size = UDim2.new(0, barW, 1, 0),
					BackgroundColor3 = Color3.new(0, 0, 0),
					BackgroundTransparency = 0.55,
					BorderSizePixel = 0,
					Active = false,
				}),
				center = e("Frame", {
					LayoutOrder = 2,
					Size = UDim2.new(0, side, 1, 0),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Active = false,
				}, {
					readout = readout,
					resetCameraBtn = resetCameraBtn,
				}),
				right = e("Frame", {
					LayoutOrder = 3,
					Size = UDim2.new(0, barW, 1, 0),
					BackgroundColor3 = Color3.new(0, 0, 0),
					BackgroundTransparency = 0.55,
					BorderSizePixel = 0,
					Active = false,
				}),
			})
		else
			local barH = (oh - side) / 2
			aspectOverlay = e("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Active = false,
				ZIndex = 2,
			}, {
				layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Top,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					Padding = UDim.new(0, 0),
				}),
				top = e("Frame", {
					LayoutOrder = 1,
					Size = UDim2.new(1, 0, 0, barH),
					BackgroundColor3 = Color3.new(0, 0, 0),
					BackgroundTransparency = 0.55,
					BorderSizePixel = 0,
					Active = false,
				}),
				center = e("Frame", {
					LayoutOrder = 2,
					Size = UDim2.new(1, 0, 0, side),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Active = false,
				}, {
					readout = readout,
					resetCameraBtn = resetCameraBtn,
				}),
				bottom = e("Frame", {
					LayoutOrder = 3,
					Size = UDim2.new(1, 0, 0, barH),
					BackgroundColor3 = Color3.new(0, 0, 0),
					BackgroundTransparency = 0.55,
					BorderSizePixel = 0,
					Active = false,
				}),
			})
		end
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 99,
		[React.Event.MouseEnter] = function()
			pointerInViewportRef.current = true
			setPointerInViewport(true)
		end,
		[React.Event.MouseLeave] = function()
			pointerInViewportRef.current = false
			mouseIcon.clearIcon()
			setPointerInViewport(false)
		end,
	}, {
		viewport = e("ViewportFrame", {
			ref = vpRef,
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground),
			BorderSizePixel = 0,
			Ambient = props.lighting.ambient,
			LightDirection = Vector3.new(props.lighting.lightDirectionX, props.lighting.lightDirectionY, props.lighting.lightDirectionZ),
			LightColor = props.lighting.lightColor,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
			aspectOverlay = aspectOverlay,
			_TrackballInput = e("ImageButton", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ImageTransparency = 1,
				AutoButtonColor = false,
				ZIndex = 1,
				[React.Event.InputBegan] = trackball.onInputBegan,
				[React.Event.InputChanged] = function(rbx, input)
					if input.UserInputType == Enum.UserInputType.MouseWheel then
						local direction = math.sign(input.Position.Z)
						props.onScroll(direction)
					else
						trackball.onInputChanged(rbx, input)
					end
				end,
				[React.Event.InputEnded] = trackball.onInputEnded,
				[React.Event.MouseLeave] = trackball.onMouseLeave,
			}),
			empty = emptyLabel,
			animationPanel = animPanel,
		}),
	})
end

return PreviewViewport

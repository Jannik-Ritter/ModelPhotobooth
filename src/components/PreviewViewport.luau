local RunService = game:GetService("RunService")

local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local getCF = require(script.Parent.Parent.lib.getCF)
local useTrackball = require(script.Parent.Parent.hooks.useTrackball)
local AnimationPanel = require(script.Parent.AnimationPanel)

local e = React.createElement

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
	isShiftDown: () -> boolean,
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
}

local function PreviewViewport(props: Props)
	local theme = StudioComponents.useTheme()
	local vpRef = React.useRef(nil :: ViewportFrame?)
	local camRef = React.useRef(nil :: Camera?)
	local cloneRef = React.useRef(nil :: Instance?)
	local worldModelRef = React.useRef(nil :: WorldModel?)
	local trackRef = React.useRef(nil :: AnimationTrack?)
	local animatorRef = React.useRef(nil :: Animator?)
	local isPlayingRef = React.useRef(false)
	local yawRef = React.useRef(props.yaw)
	local pitchRef = React.useRef(props.pitch)
	local fovRef = React.useRef(props.fov)
	local distanceRef = React.useRef(props.cameraDistance)
	local rollRef = React.useRef(props.roll)
	local offsetXRef = React.useRef(props.offsetX)
	local offsetYRef = React.useRef(props.offsetY)
	local offsetZRef = React.useRef(props.offsetZ)

	-- Keep refs in sync
	React.useEffect(function()
		yawRef.current = props.yaw
	end, { props.yaw })
	React.useEffect(function()
		pitchRef.current = props.pitch
	end, { props.pitch })
	React.useEffect(function()
		rollRef.current = props.roll
	end, { props.roll })
	React.useEffect(function()
		fovRef.current = props.fov
	end, { props.fov })
	React.useEffect(function()
		distanceRef.current = props.cameraDistance
	end, { props.cameraDistance })
	React.useEffect(function()
		offsetXRef.current = props.offsetX
	end, { props.offsetX })
	React.useEffect(function()
		offsetYRef.current = props.offsetY
	end, { props.offsetY })
	React.useEffect(function()
		offsetZRef.current = props.offsetZ
	end, { props.offsetZ })
	React.useEffect(function()
		isPlayingRef.current = props.animationPlaying
	end, { props.animationPlaying })

	-- Clone model into viewport (using WorldModel for animation support)
	local activeInstance = if props.entry then props.entry.instance else nil
	React.useEffect(function()
		local vp = vpRef.current
		if not vp or not activeInstance then
			return
		end
		local cam = Instance.new("Camera")
		cam.Parent = vp
		vp.CurrentCamera = cam

		local worldModel = Instance.new("WorldModel")
		worldModel.Parent = vp

		local clone
		local ok = pcall(function()
			clone = activeInstance:Clone()
			clone.Parent = worldModel
		end)
		if not ok or not clone then
			cam:Destroy()
			worldModel:Destroy()
			return
		end
		camRef.current = cam
		cloneRef.current = clone
		worldModelRef.current = worldModel

		cam.FieldOfView = math.max(props.fov, 1)
		cam.CFrame = getCF(
			clone,
			props.yaw,
			props.pitch,
			props.fov,
			props.cameraDistance,
			props.roll,
			Vector3.new(props.offsetX, props.offsetY, props.offsetZ)
		)
		return function()
			if trackRef.current then
				trackRef.current:Stop()
				trackRef.current:Destroy()
				trackRef.current = nil
			end
			animatorRef.current = nil
			cam:Destroy()
			worldModel:Destroy()
			camRef.current = nil
			cloneRef.current = nil
			worldModelRef.current = nil
		end
	end, { activeInstance } :: { any })

	-- Load animation track when active animation changes
	React.useEffect(function()
		local clone = cloneRef.current
		if not clone then
			return
		end

		-- Clean up previous track
		if trackRef.current then
			trackRef.current:Stop()
			trackRef.current:Destroy()
			trackRef.current = nil
		end

		if not props.activeAnimationIndex then
			animatorRef.current = nil
			return
		end

		local animInfo = props.animations[props.activeAnimationIndex]
		if not animInfo then
			return
		end

		-- Find or create animator host
		local animator
		local humanoid = clone:FindFirstChildWhichIsA("Humanoid")
		local animController = clone:FindFirstChildWhichIsA("AnimationController")
		if humanoid then
			animator = humanoid:FindFirstChildWhichIsA("Animator")
			if not animator then
				animator = Instance.new("Animator")
				animator.Parent = humanoid
			end
		else
			if not animController then
				animController = Instance.new("AnimationController")
				animController.Parent = clone
			end
			animator = animController:FindFirstChildWhichIsA("Animator")
			if not animator then
				animator = Instance.new("Animator")
				animator.Parent = animController
			end
		end
		animatorRef.current = animator

		-- Load animation
		local anim = Instance.new("Animation")
		anim.AnimationId = animInfo.animationId
		local track
		local loadOk = pcall(function()
			track = animator:LoadAnimation(anim)
		end)
		if not loadOk or not track then
			return
		end

		track.Looped = true
		track:Play(0)
		track:AdjustSpeed(0) -- start paused
		trackRef.current = track

		-- Wait for length to become available, then report it
		task.spawn(function()
			local attempts = 0
			while track.Length == 0 and attempts < 100 do
				task.wait(0.05)
				attempts += 1
			end
			if track.Length > 0 then
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

	-- Control play/pause
	React.useEffect(function()
		local track = trackRef.current
		if not track then
			return
		end
		if props.animationPlaying then
			track:AdjustSpeed(1)
		else
			track:AdjustSpeed(0)
		end
	end, { props.animationPlaying })

	-- Scrub when paused (external time position change from scrubber)
	React.useEffect(function()
		local track = trackRef.current
		if not track or isPlayingRef.current then
			return
		end
		track.TimePosition = props.animationTimePosition
		local humanoid = cloneRef.current:FindFirstChildWhichIsA("Humanoid")

		local dt = 0.1
		humanoid.Animator:StepAnimations(dt)
	end, { props.animationTimePosition })

	-- Heartbeat sync during playback
	React.useEffect(function()
		if not props.animationPlaying then
			return
		end
		local track = trackRef.current
		if not track then
			return
		end

		local lastUpdate = 0
		local conn = RunService.Heartbeat:Connect(function()
			local now = tick()
			if now - lastUpdate >= 0.05 then
				lastUpdate = now
				if track.IsPlaying then
					props.onSetTimePosition(track.TimePosition)
				end
			end
		end)

		return function()
			conn:Disconnect()
		end
	end, { props.animationPlaying })

	-- Update camera when angles, distance, or offset change
	React.useEffect(
		function()
			if camRef.current and cloneRef.current then
				camRef.current.FieldOfView = math.max(props.fov, 1)
				camRef.current.CFrame = getCF(
					cloneRef.current,
					props.yaw,
					props.pitch,
					props.fov,
					props.cameraDistance,
					props.roll,
					Vector3.new(props.offsetX, props.offsetY, props.offsetZ)
				)
			end
		end,
		{
			props.yaw,
			props.pitch,
			props.fov,
			props.cameraDistance,
			props.roll,
			props.offsetX,
			props.offsetY,
			props.offsetZ,
		} :: { any }
	)

	-- Trackball / translate
	local trackball = useTrackball(function(dx: number, dy: number)
		local shiftHeld = props.isShiftDown()

		if shiftHeld then
			local clone = cloneRef.current
			local szMag = 4 * math.sqrt(3)
			if clone then
				pcall(function()
					if clone:IsA("Model") then
						local _, s = clone:GetBoundingBox()
						szMag = s.Magnitude
					else
						szMag = (clone :: BasePart).Size.Magnitude
					end
				end)
			end
			local vpWidth = vpRef.current and vpRef.current.AbsoluteSize.X or 400
			local scale = szMag * 1.18 * distanceRef.current / vpWidth
			local rot = CFrame.fromEulerAnglesYXZ(0, math.rad(yawRef.current), 0)
				* CFrame.fromEulerAnglesYXZ(math.rad(-pitchRef.current), 0, 0)
			local right = rot * Vector3.new(1, 0, 0)
			local up = rot * Vector3.new(0, 1, 0)
			local delta = right * (-dx * scale) + up * (dy * scale)
			offsetXRef.current += delta.X
			offsetYRef.current += delta.Y
			offsetZRef.current += delta.Z
			if camRef.current and cloneRef.current then
				camRef.current.CFrame = getCF(
					cloneRef.current,
					yawRef.current,
					pitchRef.current,
					fovRef.current,
					distanceRef.current,
					rollRef.current,
					Vector3.new(offsetXRef.current, offsetYRef.current, offsetZRef.current)
				)
			end
			props.onTranslate(delta.X, delta.Y, delta.Z)
		else
			yawRef.current = yawRef.current - dx * 0.5
			pitchRef.current = pitchRef.current + dy * 0.5
			if camRef.current and cloneRef.current then
				camRef.current.CFrame = getCF(
					cloneRef.current,
					yawRef.current,
					pitchRef.current,
					fovRef.current,
					distanceRef.current,
					rollRef.current,
					Vector3.new(offsetXRef.current, offsetYRef.current, offsetZRef.current)
				)
			end
			props.onTrackball(-dx * 0.5, dy * 0.5)
		end
	end)

	-- Empty state
	local emptyLabel = nil
	if not props.entry then
		emptyLabel = e(StudioComponents.Label, {
			Text = "Select a model in Explorer",
			Size = UDim2.fromScale(1, 1),
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 5,
		})
	end

	-- Angle readout
	local readout = e("TextLabel", {
		Text = string.format(
			"%.0f\u{00B0}  %.0f\u{00B0}  R%.0f\u{00B0}",
			wrapSigned180(props.yaw),
			wrapSigned180(props.pitch),
			wrapSigned180(props.roll)
		),
		Size = UDim2.fromOffset(120, 20),
		Position = UDim2.new(0, 8, 1, -28),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 12,
		Font = Enum.Font.SourceSans,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 15,
	}, {
		corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
	})

	-- Animation panel overlay
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

	return e("Frame", {
		Size = UDim2.new(1, -220, 1, -96),
		BackgroundTransparency = 1,
	}, {
		aspectRatioConstraint = e("UIAspectRatioConstraint", {
			AspectRatio = 1,
		}),
		padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
		}),
		viewport = e("ViewportFrame", {
			ref = vpRef,
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground),
			BorderSizePixel = 0,
			Ambient = Color3.fromRGB(160, 160, 160),
			LightDirection = Vector3.new(-1, -2, -1),
			LightColor = Color3.new(1, 1, 1),
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
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
			readout = readout,
			animationPanel = animPanel,
		}),
	})
end

return PreviewViewport

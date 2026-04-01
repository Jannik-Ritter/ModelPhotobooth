local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)
local Types = require(script.Parent.Parent.Types)

local applyCamera = require(script.Parent.Parent.lib.applyCamera)
local StoreContext = require(script.Parent.Parent.StoreContext)
local useTrackball = require(script.Parent.Parent.hooks.useTrackball)
local useAnimationPlayback = require(script.Parent.Parent.hooks.useAnimationPlayback)
local Constants = require(script.Parent.Parent.Constants)
local AnimationPanel = require(script.Parent.AnimationPanel)
local ModelViewport = require(script.Parent.ModelViewport)

local e = React.createElement

local DEFAULT_VP_WIDTH = 400
local ROTATION_SENSITIVITY = 0.5

local CURSOR_ORBIT_HOVER = "rbxasset://SystemCursors/OpenHand"
local CURSOR_ORBIT_DRAG = "rbxasset://SystemCursors/ClosedHand"
local CURSOR_PAN = "rbxasset://SystemCursors/Cross"

-- Equivalent angle in (-180, 180] for display (rotation math uses unbounded degrees)
local function wrapSigned180(deg: number): number
	local x = (deg % 360 + 360) % 360
	if x > 180 then
		return x - 360
	end
	return x
end

type AnimationInfo = Types.AnimationInfo

type Props = {
	entry: {
		instance: Instance,
		status: string,
		image: EditableImage?,
		isExported: boolean,
	}?,
	onTrackball: (dYaw: number, dPitch: number) -> (),
	onTranslate: (dx: number, dy: number, dz: number) -> (),
	onScroll: (direction: number) -> (),
	onResetCamera: () -> (),
	isShiftDown: () -> boolean,
	shiftDown: boolean,
	-- Animation
	onSelectAnimation: (index: number?) -> (),
	onSetPlaying: (playing: boolean) -> (),
	onSetTimePosition: (time: number) -> (),
	onSetLength: (length: number) -> (),
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

local function toCameraStateParams(state: CameraState): applyCamera.CameraParams
	return {
		yaw = state.yaw,
		pitch = state.pitch,
		roll = state.roll,
		fov = state.fov,
		cameraDistance = state.distance,
		offsetX = state.offsetX,
		offsetY = state.offsetY,
		offsetZ = state.offsetZ,
	}
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
	local store = StoreContext.useStore()
	local state = store.state
	local dispatch = store.dispatch
	local theme = StudioComponents.useTheme()
	local mouseIcon = StudioComponents.useMouseIcon()
	local pointerInViewport, setPointerInViewport = React.useState(false)
	local pointerInViewportRef = React.useRef(false)

	-- Shared refs for ModelViewport and animation logic
	local vpRef = React.useRef(nil :: ViewportFrame?)
	local camRef = React.useRef(nil :: Camera?)
	local cloneRef = React.useRef(nil :: Instance?)
	local boundsRef = React.useRef(nil :: { cf: CFrame, size: Vector3 }?)

	local cameraStateRef = React.useRef({
		yaw = state.yaw,
		pitch = state.pitch,
		roll = state.roll,
		fov = state.fov,
		distance = state.cameraDistance,
		offsetX = state.cameraOffsetX,
		offsetY = state.cameraOffsetY,
		offsetZ = state.cameraOffsetZ,
	} :: CameraState)

	-- Keep event handlers in sync with latest values without many tiny effects.
	cameraStateRef.current = {
		yaw = state.yaw,
		pitch = state.pitch,
		roll = state.roll,
		fov = state.fov,
		distance = state.cameraDistance,
		offsetX = state.cameraOffsetX,
		offsetY = state.cameraOffsetY,
		offsetZ = state.cameraOffsetZ,
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
	end, { activeInstance })

	useAnimationPlayback(state, dispatch, activeInstance, {
		cloneRef = cloneRef,
		camRef = camRef,
		boundsRef = boundsRef,
		cameraStateRef = cameraStateRef,
	})

	-- Trackball / translate
	local trackball = useTrackball(function(dx: number, dy: number)
		local camera = camRef.current
		local clone = cloneRef.current
		local camState = cameraStateRef.current
		if not camera or not clone then
			return
		end

		if props.isShiftDown() then
			local vpWidth = if vpRef.current then vpRef.current.AbsoluteSize.X else DEFAULT_VP_WIDTH
			local scale = getCloneSizeMagnitude(clone) * 1.18 * camState.distance / vpWidth
			local rot = CFrame.fromEulerAnglesYXZ(0, math.rad(camState.yaw), 0)
				* CFrame.fromEulerAnglesYXZ(math.rad(-camState.pitch), 0, 0)
			local right = rot * Vector3.new(1, 0, 0)
			local up = rot * Vector3.new(0, 1, 0)
			local delta = right * (-dx * scale) + up * (dy * scale)

			camState.offsetX += delta.X
			camState.offsetY += delta.Y
			camState.offsetZ += delta.Z
			camState.offsetX = math.clamp(camState.offsetX, Constants.CAMERA_OFFSET_MIN, Constants.CAMERA_OFFSET_MAX)
			camState.offsetY = math.clamp(camState.offsetY, Constants.CAMERA_OFFSET_MIN, Constants.CAMERA_OFFSET_MAX)
			camState.offsetZ = math.clamp(camState.offsetZ, Constants.CAMERA_OFFSET_MIN, Constants.CAMERA_OFFSET_MAX)
			applyCamera(camera, clone, toCameraStateParams(camState), boundsRef.current)
			props.onTranslate(delta.X, delta.Y, delta.Z)
			return
		end

		local yawDelta = -dx * ROTATION_SENSITIVITY
		local pitchDelta = dy * ROTATION_SENSITIVITY
		camState.yaw += yawDelta
		camState.pitch += pitchDelta
		applyCamera(camera, clone, toCameraStateParams(camState), boundsRef.current)
		props.onTrackball(yawDelta, pitchDelta)
	end)

	local isDragging = trackball.isDragging

	-- plugin:GetMouse().Icon is global. Ref syncs on leave before React state so a late Heartbeat/effect
	-- cannot setIcon after React state so cursor updates when Shift toggles.
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
				wrapSigned180(state.yaw),
				wrapSigned180(state.pitch),
				wrapSigned180(state.roll)
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
	if #state.animations > 0 then
		animPanel = e(AnimationPanel, {
			animations = state.animations,
			activeAnimationIndex = state.activeAnimationIndex,
			playing = state.animationPlaying,
			timePosition = state.animationTimePosition,
			length = state.animationLength,
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
		viewport = if activeInstance
			then e(ModelViewport, {
				instance = activeInstance,
				lighting = state.lighting,
				camera = {
					yaw = state.yaw,
					pitch = state.pitch,
					roll = state.roll,
					fov = state.fov,
					cameraDistance = state.cameraDistance,
					offsetX = state.cameraOffsetX,
					offsetY = state.cameraOffsetY,
					offsetZ = state.cameraOffsetZ,
				},
				refs = {
					viewportFrame = vpRef,
					camera = camRef,
					clone = cloneRef,
					bounds = boundsRef,
				},
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground),
				BorderSizePixel = 0,
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
			})
			else nil,
	})
end

return PreviewViewport

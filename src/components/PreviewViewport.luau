local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local getCF = require(script.Parent.Parent.lib.getCF)
local useTrackball = require(script.Parent.Parent.hooks.useTrackball)

local e = React.createElement

-- Equivalent angle in (-180, 180] for display (rotation math uses unbounded degrees)
local function wrapSigned180(deg: number): number
	local x = (deg % 360 + 360) % 360
	if x > 180 then
		return x - 360
	end
	return x
end

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
}

local function PreviewViewport(props: Props)
	local theme = StudioComponents.useTheme()
	local vpRef = React.useRef(nil :: ViewportFrame?)
	local camRef = React.useRef(nil :: Camera?)
	local cloneRef = React.useRef(nil :: Instance?)
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

	-- Clone model into viewport
	local activeInstance = if props.entry then props.entry.instance else nil
	React.useEffect(function()
		local vp = vpRef.current
		if not vp or not activeInstance then
			return
		end
		local cam = Instance.new("Camera")
		cam.Parent = vp
		vp.CurrentCamera = cam
		local clone
		local ok = pcall(function()
			clone = activeInstance:Clone()
			clone.Parent = vp
		end)
		if not ok or not clone then
			cam:Destroy()
			return
		end
		camRef.current = cam
		cloneRef.current = clone
		cam.FieldOfView = math.max(props.fov, 1)
		cam.CFrame = getCF(clone, props.yaw, props.pitch, props.fov, props.cameraDistance, props.roll,
			Vector3.new(props.offsetX, props.offsetY, props.offsetZ))
		return function()
			cam:Destroy()
			if clone then
				clone:Destroy()
			end
			camRef.current = nil
			cloneRef.current = nil
		end
	end, { activeInstance } :: { any })

	-- Update camera when angles, distance, or offset change
	React.useEffect(function()
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
	end, { props.yaw, props.pitch, props.fov, props.cameraDistance, props.roll, props.offsetX, props.offsetY, props.offsetZ } :: { any })

	-- Trackball / translate
	local trackball = useTrackball(function(dx: number, dy: number)
		local shiftHeld = props.isShiftDown()

		if shiftHeld then
			-- Translate: compute world-space delta along camera plane.
			-- Scale = sz.Magnitude * 1.18 * distMult / vpWidth, so dragging the full
			-- viewport width shifts the target by exactly one viewport-width of world space.
			local clone = cloneRef.current
			local szMag = 4 * math.sqrt(3) -- fallback: magnitude of Vector3(4,4,4)
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
			-- Rotate
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

	return e("Frame", {
		Size = UDim2.new(1, -220, 1, -96),
		BackgroundTransparency = 1,
	}, {
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
		}),
	})
end

return PreviewViewport

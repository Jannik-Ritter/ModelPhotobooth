local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages._Index["jsdotlua_react@17.2.1"]["react"])
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
	fov: number,
	onTrackball: (dYaw: number, dPitch: number) -> (),
}

local function PreviewViewport(props: Props)
	local theme = StudioComponents.useTheme()
	local vpRef = React.useRef(nil :: ViewportFrame?)
	local camRef = React.useRef(nil :: Camera?)
	local cloneRef = React.useRef(nil :: Instance?)
	local yawRef = React.useRef(props.yaw)
	local pitchRef = React.useRef(props.pitch)

	-- Keep refs in sync
	React.useEffect(function()
		yawRef.current = props.yaw
	end, { props.yaw })
	React.useEffect(function()
		pitchRef.current = props.pitch
	end, { props.pitch })

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
		cam.CFrame = getCF(clone, props.yaw, props.pitch, props.fov)
		return function()
			cam:Destroy()
			if clone then
				clone:Destroy()
			end
			camRef.current = nil
			cloneRef.current = nil
		end
	end, { activeInstance } :: { any })

	-- Update camera when angles change
	React.useEffect(function()
		if camRef.current and cloneRef.current then
			camRef.current.FieldOfView = math.max(props.fov, 1)
			camRef.current.CFrame = getCF(cloneRef.current, props.yaw, props.pitch, props.fov)
		end
	end, { props.yaw, props.pitch, props.fov } :: { any })

	-- Trackball
	local trackball = useTrackball(function(dx: number, dy: number)
		yawRef.current = yawRef.current - dx * 0.5
		pitchRef.current = pitchRef.current + dy * 0.5
		if camRef.current and cloneRef.current then
			camRef.current.CFrame = getCF(cloneRef.current, yawRef.current, pitchRef.current, props.fov)
		end
		props.onTrackball(-dx * 0.5, dy * 0.5)
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
		Text = string.format("%.0f\u{00B0}  %.0f\u{00B0}", wrapSigned180(props.yaw), wrapSigned180(props.pitch)),
		Size = UDim2.new(0, 80, 0, 20),
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
				[React.Event.InputChanged] = trackball.onInputChanged,
				[React.Event.InputEnded] = trackball.onInputEnded,
				[React.Event.MouseLeave] = trackball.onMouseLeave,
			}),
			empty = emptyLabel,
			readout = readout,
		}),
	})
end

return PreviewViewport

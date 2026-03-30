local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local getCF = require(script.Parent.Parent.lib.getCF)

local e = React.createElement

local STATUS_COLORS = {
	idle = Color3.fromRGB(70, 70, 70),
	pending = Color3.fromRGB(255, 190, 0),
	ok = Color3.fromRGB(50, 210, 80),
	fail = Color3.fromRGB(220, 60, 60),
}

local THUMB_SIZE = 80
-- 2 top + content + 2 gap + 16 name row + 2 bottom = THUMB_SIZE (name row fits Studio Label / default text size)
local CONTENT_HEIGHT = 58
local NAME_TOP = 62

type Props = {
	entry: {
		instance: Instance,
		status: string,
		image: EditableImage?,
		isExported: boolean,
	},
	yaw: number,
	pitch: number,
	roll: number,
	fov: number,
	offsetX: number,
	offsetY: number,
	offsetZ: number,
	isActive: boolean,
	onSelect: () -> (),
	onPreview: (() -> ())?,
	LayoutOrder: number,
}

-- Thumb tile: themed InputFieldBackground card + Border/MainButton stroke (like PreviewViewport); Studio Label for caption.
local function ModelThumb(props: Props)
	local theme = StudioComponents.useTheme()
	local vpRef = React.useRef(nil :: ViewportFrame?)
	local hovered, setHovered = React.useState(false)

	-- Clone model into small viewport
	React.useEffect(
		function()
			local vp = vpRef.current
			if not vp then
				return
			end
			local cam = Instance.new("Camera")
			cam.Parent = vp
			vp.CurrentCamera = cam
			local clone
			local ok = pcall(function()
				clone = props.entry.instance:Clone()
				clone.Parent = vp
			end)
			if not ok or not clone then
				cam:Destroy()
				return
			end
			cam.FieldOfView = math.max(props.fov, 1)
			cam.CFrame = getCF(
				clone,
				props.yaw,
				props.pitch,
				props.fov,
				nil,
				props.roll,
				Vector3.new(props.offsetX, props.offsetY, props.offsetZ)
			)
			return function()
				cam:Destroy()
				if clone then
					clone:Destroy()
				end
			end
		end,
		{
			props.entry.instance,
			props.yaw,
			props.pitch,
			props.fov,
			props.roll,
			props.offsetX,
			props.offsetY,
			props.offsetZ,
		} :: { any }
	)

	-- Show captured image if available
	local content
	if props.entry.image then
		content = e("ImageLabel", {
			Size = UDim2.fromOffset(THUMB_SIZE - 4, CONTENT_HEIGHT),
			Position = UDim2.fromOffset(2, 2),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground),
			BorderSizePixel = 0,
			ImageContent = Content.fromObject(props.entry.image),
			ScaleType = Enum.ScaleType.Fit,
		}, {})
	else
		content = e("ViewportFrame", {
			ref = vpRef,
			Size = UDim2.fromOffset(THUMB_SIZE - 4, CONTENT_HEIGHT),
			Position = UDim2.fromOffset(2, 2),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground),
			BorderSizePixel = 0,
			Ambient = Color3.fromRGB(160, 160, 160),
			LightDirection = Vector3.new(-1, -2, -1),
			LightColor = Color3.new(1, 1, 1),
		}, {})
	end

	-- Magnify icon shown on hover when a capture exists
	local previewIcon = nil
	if hovered and props.entry.image and props.onPreview then
		previewIcon = e("ImageButton", {
			-- Centered over the content area
			Size = UDim2.fromOffset(24, 24),
			Position = UDim2.fromOffset(THUMB_SIZE / 2 - 12, 2 + CONTENT_HEIGHT / 2 - 12),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.35,
			Image = "rbxassetid://86368281871088",
			ImageColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = 10,
			[React.Event.Activated] = props.onPreview,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
		})
	end

	local accentColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton)

	return e("TextButton", {
		Size = UDim2.fromOffset(THUMB_SIZE, THUMB_SIZE),
		BackgroundColor3 = if props.isActive
			then accentColor
			else theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground),
		BackgroundTransparency = if props.isActive then 0 else 0,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = props.LayoutOrder,
		[React.Event.Activated] = props.onSelect,
		[React.Event.MouseEnter] = function()
			setHovered(true)
		end,
		[React.Event.MouseLeave] = function()
			setHovered(false)
		end,
	}, {
		stroke = e("UIStroke", {
			Color = if props.isActive then accentColor else theme:GetColor(Enum.StudioStyleGuideColor.Border),
			Thickness = if props.isActive then 2 else 1,
		}),
		content = content,
		previewIcon = previewIcon,
		nameLabel = e(StudioComponents.Label, {
			Text = props.entry.instance.Name,
			Size = UDim2.fromOffset(THUMB_SIZE - 4, 16),
			Position = UDim2.fromOffset(2, NAME_TOP),
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			--TextColor3 = Color3.new(1, 1, 1),
			TextColorStyle = if props.isActive then nil else Enum.StudioStyleGuideColor.SubText,
		}),
		statusDot = e("Frame", {
			Size = UDim2.fromOffset(8, 8),
			Position = UDim2.new(1, -10, 0, 4),
			BackgroundColor3 = STATUS_COLORS[props.entry.status] or STATUS_COLORS.idle,
			BorderSizePixel = 0,
			ZIndex = 5,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
		}),
	})
end

return ModelThumb

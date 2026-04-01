local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local StoreContext = require(script.Parent.Parent.StoreContext)
local ModelViewport = require(script.Parent.ModelViewport)

local e = React.createElement

local STATUS_COLORS = {
	idle = Color3.fromRGB(70, 70, 70),
	pending = Color3.fromRGB(255, 190, 0),
	ok = Color3.fromRGB(50, 210, 80),
	fail = Color3.fromRGB(220, 60, 60),
}

local NAME_ROW_HEIGHT = 16

type Props = {
	entry: {
		instance: Instance,
		status: string,
		image: EditableImage?,
		isExported: boolean,
	},
	thumbSize: number,
	isActive: boolean,
	onSelect: () -> (),
	onPreview: (() -> ())?,
	LayoutOrder: number,
}

-- Thumb tile: themed InputFieldBackground card + Border/MainButton stroke (like PreviewViewport); Studio Label for caption.
local function ModelThumb(props: Props)
	local store = StoreContext.useStore()
	local state = store.state
	local theme = StudioComponents.useTheme()
	local hovered, setHovered = React.useState(false)

	-- Always show live ViewportFrame; rendered images go to the Renders tab
	local s = props.thumbSize
	local contentH = s - NAME_ROW_HEIGHT - 4
	local content = e(ModelViewport, {
		instance = props.entry.instance,
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
		Size = UDim2.fromOffset(s - 4, contentH),
		Position = UDim2.fromOffset(2, 2),
		BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground),
		BorderSizePixel = 0,
	}, {})

	-- Magnify icon centered over the content area
	local previewIcon = nil
	if hovered and props.entry.image and props.onPreview then
		previewIcon = e("ImageButton", {
			Size = UDim2.fromOffset(24, 24),
			Position = UDim2.fromOffset(s / 2 - 12, 2 + contentH / 2 - 12),
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
		Size = UDim2.fromOffset(s, s),
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
			Size = UDim2.fromOffset(s - 4, NAME_ROW_HEIGHT),
			Position = UDim2.fromOffset(2, s - NAME_ROW_HEIGHT - 2),
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
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

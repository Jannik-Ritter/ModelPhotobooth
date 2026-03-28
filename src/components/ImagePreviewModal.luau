local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages._Index["jsdotlua_react@17.2.1"]["react"])
local StudioComponents = require(Packages.studiocomponents)

local Darkener = require(script.Parent.Darkener)

local e = React.createElement

type Props = {
	image: EditableImage,
	title: string,
	onClose: () -> (),
}

local function ImagePreviewModal(props: Props)
	local theme = StudioComponents.useTheme()

	return e(Darkener, {
		onBackdropClick = props.onClose,
	}, {
		panel = e("Frame", {
			Size = UDim2.fromScale(0.8, 0.8),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
			BorderSizePixel = 0,
			Active = true,
		}, {
			titleBar = e("Frame", {
				Size = UDim2.new(1, 0, 0, 32),
				BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Titlebar),
				BorderSizePixel = 0,
			}, {
				border = e("Frame", {
					Size = UDim2.new(1, 0, 0, 1),
					Position = UDim2.new(0, 0, 1, -1),
					BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
					BorderSizePixel = 0,
				}),
				title = e("TextLabel", {
					Text = "Preview — " .. props.title,
					Size = UDim2.new(1, -40, 1, 0),
					Position = UDim2.fromOffset(10, 0),
					BackgroundTransparency = 1,
					TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
					TextSize = 13,
					Font = Enum.Font.SourceSans,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
				}),
				close = e("ImageButton", {
					Size = UDim2.fromOffset(16, 16),
					Position = UDim2.new(1, -24, 0.5, -8),
					BackgroundTransparency = 1,
					Image = "rbxassetid://129976509676301",
					ImageColor3 = theme:GetColor(Enum.StudioStyleGuideColor.SubText),
					[React.Event.Activated] = props.onClose,
				}),
			}),
			image = e("ImageLabel", {
				Size = UDim2.new(1, -16, 1, -40),
				Position = UDim2.fromOffset(8, 32),
				BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground),
				BorderSizePixel = 0,
				ImageContent = Content.fromObject(props.image),
				ScaleType = Enum.ScaleType.Fit,
			}),
		}),
	})
end

return ImagePreviewModal

local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local Darkener = require(script.Parent.Darkener)
local ModalCloseButton = require(script.Parent.ModalCloseButton)

local e = React.createElement

type Props = {
	image: EditableImage,
	title: string,
	onClose: () -> (),
	onExport: () -> (),
	onRerender: () -> (),
	onPrev: (() -> ())?,
	onNext: (() -> ())?,
	hasPrev: boolean,
	hasNext: boolean,
	rendering: boolean,
}

local function ImagePreviewModal(props: Props)
	local theme = StudioComponents.useTheme()

	return e(Darkener, {
		onBackdropClick = function() end,
	}, {
		panel = e("Frame", {
			Size = UDim2.fromScale(0.8, 0.8),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
			BorderSizePixel = 0,
			Active = true,
			ClipsDescendants = true,
		}, {
			ratioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 1,
			}),
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
					TextSize = 17,
					Font = Enum.Font.SourceSans,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
				}),
				close = e(ModalCloseButton, {
					onActivated = props.onClose,
				}),
			}),
			image = e("ImageLabel", {
				Size = UDim2.new(1, 0, 1, -68),
				Position = UDim2.fromOffset(0, 32),
				BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground),
				BorderSizePixel = 0,
				ImageContent = Content.fromObject(props.image),
				ScaleType = Enum.ScaleType.Fit,
			}),
			prevArrow = if props.hasPrev
				then e(StudioComponents.Button, {
					Icon = {
						Image = "rbxassetid://93292117732993",
						Size = Vector2.new(16, 16),
						UseThemeColor = true,
					},
					OnActivated = props.onPrev,
					Disabled = props.rendering,
					Size = UDim2.fromOffset(32, 48),
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 8, 0.5, 0),
					ZIndex = 2,
				})
				else nil,
			nextArrow = if props.hasNext
				then e(StudioComponents.Button, {
					Icon = {
						Image = "rbxassetid://70823822486733",
						Size = Vector2.new(16, 16),
						UseThemeColor = true,
					},
					OnActivated = props.onNext,
					Disabled = props.rendering,
					Size = UDim2.fromOffset(32, 48),
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -8, 0.5, 0),
					ZIndex = 2,
				})
				else nil,
			footer = e("Frame", {
				Size = UDim2.new(1, 0, 0, 36),
				Position = UDim2.new(0, 0, 1, -36),
				BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Titlebar),
				BorderSizePixel = 0,
			}, {
				border = e("Frame", {
					Size = UDim2.new(1, 0, 0, 1),
					Position = UDim2.fromOffset(0, 0),
					BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
					BorderSizePixel = 0,
				}),
				layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6),
					VerticalAlignment = Enum.VerticalAlignment.Center,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
				}),
				padding = e("UIPadding", {
					PaddingRight = UDim.new(0, 8),
				}),
				rerender = e(StudioComponents.Button, {
					Text = "Re-render",
					OnActivated = props.onRerender,
					Disabled = props.rendering,
					Size = UDim2.fromOffset(80, 24),
					LayoutOrder = 1,
				}),
				exportThis = e(StudioComponents.MainButton, {
					Text = "Export This",
					OnActivated = props.onExport,
					Disabled = props.rendering,
					Size = UDim2.fromOffset(84, 24),
					LayoutOrder = 2,
				}),
			}),
		}),
	})
end

return ImagePreviewModal

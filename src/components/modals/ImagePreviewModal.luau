local Packages = script.Parent.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local Darkener = require(script.Parent.Darkener)
local ModalTitleBar = require(script.Parent.ModalTitleBar)
local Constants = require(script.Parent.Parent.Parent.Constants)

local e = React.createElement

type Props = {
	image: EditableImage,
	title: string,
	onClose: () -> (),
	onExport: () -> (),
	onUpload: () -> (),
	onRerender: () -> (),
	onPrev: (() -> ())?,
	onNext: (() -> ())?,
	hasPrev: boolean,
	hasNext: boolean,
	rendering: boolean,
	uploading: boolean,
	hideRerender: boolean?,
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
			titleBar = e(ModalTitleBar, {
				title = "Preview — " .. props.title,
				onClose = props.onClose,
				textTruncate = Enum.TextTruncate.AtEnd,
			}),
			image = e("ImageLabel", {
				Size = UDim2.new(1, 0, 1, -68),
				Position = UDim2.fromOffset(0, Constants.MODAL_TITLE_BAR_HEIGHT),
				BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground),
				BorderSizePixel = 0,
				ImageContent = Content.fromObject(props.image),
				ScaleType = Enum.ScaleType.Fit,
			}),
			prevArrow = if props.hasPrev
				then e(StudioComponents.Button, {
					Icon = {
						Image = "rbxassetid://93292117732993",
						Size = Constants.TOOLBAR_ICON_GLYPH,
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
						Size = Constants.TOOLBAR_ICON_GLYPH,
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
				rerender = if not props.hideRerender
					then e(StudioComponents.Button, {
						Text = "Re-render",
						OnActivated = props.onRerender,
						Disabled = props.rendering,
						Size = UDim2.fromOffset(80, 24),
						LayoutOrder = 1,
					})
					else nil,
				upload = e(StudioComponents.Button, {
					Text = "Upload",
					OnActivated = props.onUpload,
					Disabled = props.rendering or props.uploading,
					Size = UDim2.fromOffset(64, 24),
					LayoutOrder = 2,
				}),
				exportThis = e(StudioComponents.MainButton, {
					Text = "Export This",
					OnActivated = props.onExport,
					Disabled = props.rendering,
					Size = UDim2.fromOffset(84, 24),
					LayoutOrder = 3,
				}),
			}),
		}),
	})
end

return ImagePreviewModal

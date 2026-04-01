local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local Store = require(script.Parent.Parent.Store)
local Constants = require(script.Parent.Parent.Constants)

local e = React.createElement

type Props = {
	entry: Store.RenderHistoryEntry,
	thumbSize: number,
	isActive: boolean,
	onPreview: () -> (),
	LayoutOrder: number,
}

local function RenderThumb(props: Props)
	local theme = StudioComponents.useTheme()

	local s = props.thumbSize
	local contentH = s - Constants.THUMB_NAME_ROW_HEIGHT - 4

	local content = e("ImageLabel", {
		Size = UDim2.fromOffset(s - 4, contentH),
		Position = UDim2.fromOffset(2, 2),
		BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground),
		BorderSizePixel = 0,
		ImageContent = Content.fromObject(props.entry.image),
		ScaleType = Enum.ScaleType.Fit,
	}, {})

	local accentColor = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton)

	return e("TextButton", {
		Size = UDim2.fromOffset(s, s),
		BackgroundColor3 = if props.isActive
			then accentColor
			else theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground),
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = props.LayoutOrder,
		[React.Event.Activated] = props.onPreview,
	}, {
		stroke = e("UIStroke", {
			Color = if props.isActive then accentColor else theme:GetColor(Enum.StudioStyleGuideColor.Border),
			Thickness = if props.isActive then Constants.STROKE_ACTIVE else Constants.STROKE_THIN,
		}),
		content = content,
		nameLabel = e(StudioComponents.Label, {
			Text = props.entry.modelName,
			Size = UDim2.fromOffset(s - 4, Constants.THUMB_NAME_ROW_HEIGHT),
			Position = UDim2.fromOffset(2, s - Constants.THUMB_NAME_ROW_HEIGHT - 2),
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextColorStyle = if props.isActive then nil else Enum.StudioStyleGuideColor.SubText,
		}),
	})
end

return RenderThumb

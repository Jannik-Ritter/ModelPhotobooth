local Packages = script.Parent.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local ModalCloseButton = require(script.Parent.ModalCloseButton)
local Constants = require(script.Parent.Parent.Parent.Constants)

local e = React.createElement

type Props = {
	title: string,
	onClose: (() -> ())?,
	layoutOrder: number?,
	textSize: number?,
	textTruncate: Enum.TextTruncate?,
}

local function ModalTitleBar(props: Props)
	local theme = StudioComponents.useTheme()
	local hasClose = props.onClose ~= nil
	local textSize = props.textSize or 18

	return e("Frame", {
		Size = UDim2.new(1, 0, 0, Constants.MODAL_TITLE_BAR_HEIGHT),
		BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Titlebar),
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
	}, {
		border = e("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 1, -1),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
			BorderSizePixel = 0,
		}),
		title = e("TextLabel", {
			Text = props.title,
			Size = UDim2.new(1, if hasClose then -40 else -16, 1, 0),
			Position = UDim2.fromOffset(10, 0),
			BackgroundTransparency = 1,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
			TextSize = textSize,
			Font = Enum.Font.SourceSans,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = props.textTruncate,
		}),
		close = if hasClose
			then e(ModalCloseButton, {
				onActivated = props.onClose,
			})
			else nil,
	})
end

return ModalTitleBar

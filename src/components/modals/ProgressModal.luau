local Packages = script.Parent.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local Darkener = require(script.Parent.Darkener)
local ModalTitleBar = require(script.Parent.ModalTitleBar)

local e = React.createElement

type Props = {
	verb: string,
	progress: number,
	total: number,
}

local function ProgressModal(props: Props)
	local theme = StudioComponents.useTheme()
	local fraction = if props.total > 0 then props.progress / props.total else 0

	return e(Darkener, {
		onBackdropClick = function() end,
	}, {
		panel = e("Frame", {
			Size = UDim2.fromOffset(340, 96),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
			BorderSizePixel = 0,
			Active = true,
		}, {
			titleBar = e(ModalTitleBar, {
				title = props.verb .. "...",
				onClose = nil,
			}),
			body = e("Frame", {
				Size = UDim2.new(1, 0, 0, 64),
				Position = UDim2.fromOffset(0, 32),
				BackgroundTransparency = 1,
			}, {
				count = e("TextLabel", {
					Text = string.format("%d / %d", props.progress, props.total),
					Size = UDim2.new(1, 0, 0, 20),
					Position = UDim2.fromOffset(0, 8),
					BackgroundTransparency = 1,
					TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
					TextSize = 16,
					Font = Enum.Font.SourceSans,
					TextXAlignment = Enum.TextXAlignment.Center,
				}),
				bar = e(StudioComponents.ProgressBar, {
					Value = fraction,
					Formatter = function(_, _)
						return "" -- intentionally hide the text label
					end,
					Size = UDim2.new(1, -32, 0, 6),
					Position = UDim2.fromOffset(16, 36),
				}),
			}),
		}),
	})
end

return ProgressModal

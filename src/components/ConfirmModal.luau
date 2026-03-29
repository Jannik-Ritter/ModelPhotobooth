local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local Darkener = require(script.Parent.Darkener)
local ModalCloseButton = require(script.Parent.ModalCloseButton)

local e = React.createElement

type Props = {
	title: string,
	message: string,
	confirmLabel: string?,
	onConfirm: () -> (),
	onClose: () -> (),
}

local function ConfirmModal(props: Props)
	local theme = StudioComponents.useTheme()
	local confirmLabel = props.confirmLabel or "Confirm"

	-- Panel height: 32 (title) + 46 (body) + 40 (footer) = 118
	return e(Darkener, {
		onBackdropClick = function() end,
	}, {
		panel = e("Frame", {
			Size = UDim2.fromOffset(300, 118),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
			BorderSizePixel = 0,
			Active = true,
		}, {
			layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			titleBar = e("Frame", {
				Size = UDim2.new(1, 0, 0, 32),
				BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Titlebar),
				BorderSizePixel = 0,
				LayoutOrder = 1,
			}, {
				border = e("Frame", {
					Size = UDim2.new(1, 0, 0, 1),
					Position = UDim2.new(0, 0, 1, -1),
					BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
					BorderSizePixel = 0,
				}),
				title = e("TextLabel", {
					Text = props.title,
					Size = UDim2.new(1, -40, 1, 0),
					Position = UDim2.fromOffset(10, 0),
					BackgroundTransparency = 1,
					TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
					TextSize = 13,
					Font = Enum.Font.SourceSans,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				close = e(ModalCloseButton, {
					onActivated = props.onClose,
				}),
			}),

			body = e("Frame", {
				Size = UDim2.new(1, 0, 0, 46),
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, {
				label = e("TextLabel", {
					Text = props.message,
					Size = UDim2.new(1, -16, 1, 0),
					Position = UDim2.fromOffset(8, 0),
					BackgroundTransparency = 1,
					TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
					TextSize = 13,
					Font = Enum.Font.SourceSans,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true,
				}),
			}),

			footer = e("Frame", {
				Size = UDim2.new(1, 0, 0, 40),
				BackgroundTransparency = 1,
				LayoutOrder = 3,
			}, {
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
				cancel = e(StudioComponents.Button, {
					Text = "Cancel",
					OnActivated = props.onClose,
					Size = UDim2.fromOffset(60, 24),
					LayoutOrder = 1,
				}),
				confirm = e(StudioComponents.MainButton, {
					Text = confirmLabel,
					OnActivated = function()
						props.onConfirm()
						props.onClose()
					end,
					Size = UDim2.fromOffset(60, 24),
					LayoutOrder = 2,
				}),
			}),
		}),
	})
end

return ConfirmModal

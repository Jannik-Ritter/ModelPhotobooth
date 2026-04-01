local Packages = script.Parent.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local Darkener = require(script.Parent.Darkener)
local ModalTitleBar = require(script.Parent.ModalTitleBar)
local Constants = require(script.Parent.Parent.Parent.Constants)

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

	-- Panel height: 32 (title) + 54 (body) + 40 (footer) = 126
	return e(Darkener, {
		onBackdropClick = function() end,
	}, {
		panel = e("Frame", {
			Size = UDim2.fromOffset(Constants.MODAL_DEFAULT_WIDTH, 126),
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

			titleBar = e(ModalTitleBar, {
				title = props.title,
				onClose = props.onClose,
				layoutOrder = 1,
			}),

			body = e("Frame", {
				Size = UDim2.new(1, 0, 0, 54),
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, {
				label = e("TextLabel", {
					Text = props.message,
					Size = UDim2.new(1, -16, 1, 0),
					Position = UDim2.fromOffset(8, 0),
					BackgroundTransparency = 1,
					TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
					TextSize = 16,
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

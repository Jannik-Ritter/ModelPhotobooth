local Packages = script.Parent.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local Darkener = require(script.Parent.Darkener)
local ModalTitleBar = require(script.Parent.ModalTitleBar)
local constants = require(script.Parent.Parent.Parent.constants)

local e = React.createElement

type Props = {
	mode: "save" | "rename",
	initialName: string?,
	onConfirm: (name: string) -> (),
	onClose: () -> (),
}

local function NameInputModal(props: Props)
	local theme = StudioComponents.useTheme()
	local text, setText = React.useState(props.initialName or "")

	React.useEffect(function()
		setText(props.initialName or "")
	end, { props.initialName })

	local title = if props.mode == "rename" then "Rename Preset" else "Save Preset"
	local confirmLabel = if props.mode == "rename" then "Rename" else "Save"

	-- Panel height: 32 (title) + 46 (body) + 40 (footer) = 118
	return e(Darkener, {
		onBackdropClick = function() end,
	}, {
		panel = e("Frame", {
			Size = UDim2.fromOffset(constants.MODAL_DEFAULT_WIDTH, 118),
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
				title = title,
				onClose = props.onClose,
				layoutOrder = 1,
			}),

			body = e("Frame", {
				Size = UDim2.new(1, 0, 0, 46),
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, {
				input = e(StudioComponents.TextInput, {
					Text = text,
					PlaceholderText = "Preset name",
					OnChanged = function(newText)
						setText(newText)
					end,
					OnFocusLost = function(newText, enterPressed)
						if enterPressed and #newText > 0 then
							props.onConfirm(newText)
							props.onClose()
						end
					end,
					Size = UDim2.new(1, -16, 0, 22),
					Position = UDim2.fromOffset(8, 12),
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
						props.onConfirm(text)
						props.onClose()
					end,
					Disabled = #text == 0,
					Size = UDim2.fromOffset(60, 24),
					LayoutOrder = 2,
				}),
			}),
		}),
	})
end

return NameInputModal

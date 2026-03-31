local Packages = script.Parent.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local Darkener = require(script.Parent.Darkener)
local ModalTitleBar = require(script.Parent.ModalTitleBar)
local constants = require(script.Parent.Parent.Parent.constants)

local e = React.createElement

local SWATCH_COLORS = {
	Color3.new(0, 0, 0),
	Color3.new(1, 1, 1),
	Color3.fromRGB(220, 60, 60),
	Color3.fromRGB(50, 130, 220),
	Color3.fromRGB(220, 170, 0),
	Color3.fromRGB(40, 180, 80),
}

type Props = {
	title: string,
	color: Color3,
	onColorChanged: (Color3) -> (),
	onClose: () -> (),
}

local function ColorPickerModal(props: Props)
	local theme = StudioComponents.useTheme()
	local intermediateColor, setIntermediateColor = React.useState(props.color)

	React.useEffect(function()
		setIntermediateColor(props.color)
	end, { props.color })

	local swatches = {}
	for i, c in ipairs(SWATCH_COLORS) do
		swatches["swatch_" .. i] = e("TextButton", {
			Size = UDim2.fromOffset(18, 18),
			BackgroundColor3 = c,
			BorderSizePixel = 0,
			Text = "",
			LayoutOrder = i,
			[React.Event.MouseButton1Click] = function()
				props.onColorChanged(c)
			end,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(0, 3) }),
			stroke = e("UIStroke", {
				Color = if props.color == c
					then theme:GetColor(Enum.StudioStyleGuideColor.MainText)
					else theme:GetColor(Enum.StudioStyleGuideColor.Border),
				Thickness = if props.color == c then 2 else 1,
			}),
		})
	end
	swatches["layout"] = e("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})

	-- Panel height: 32 (title) + 34 (swatches) + 285 (picker) + 40 (footer) = 391
	return e(Darkener, {
		onBackdropClick = function() end,
	}, {
		panel = e("Frame", {
			Size = UDim2.fromOffset(constants.MODAL_DEFAULT_WIDTH, 391),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
			BorderSizePixel = 0,
			Active = false,
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

			swatchRow = e("Frame", {
				Size = UDim2.new(1, 0, 0, 34),
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, {
				padding = e("UIPadding", {
					PaddingLeft = UDim.new(0, 10),
					PaddingTop = UDim.new(0, 8),
					PaddingBottom = UDim.new(0, 8),
				}),
				swatches = e("Frame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
				}, swatches),
			}),

			body = e("Frame", {
				Size = UDim2.new(1, 0, 0, 285),
				BackgroundTransparency = 1,
				LayoutOrder = 3,
			}, {
				picker = e(StudioComponents.ColorPicker, {
					Size = UDim2.fromScale(1, 1),
					Color = intermediateColor,
					OnChanged = function(newColor)
						setIntermediateColor(newColor)
					end,
				}),
			}),

			footer = e("Frame", {
				Size = UDim2.new(1, 0, 0, 40),
				BackgroundTransparency = 1,
				LayoutOrder = 4,
			}, {
				doneButton = e(StudioComponents.MainButton, {
					Text = "Done",
					OnActivated = function()
						props.onColorChanged(intermediateColor)
						props.onClose()
					end,
					Size = UDim2.new(1, -16, 0, 24),
					Position = UDim2.fromOffset(8, 8),
				}),
			}),
		}),
	})
end

return ColorPickerModal

local Packages = script.Parent.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local Constants = require(script.Parent.Parent.Parent.Constants)

local e = React.createElement

type Props = {
	label: string,
	enabled: boolean,
	color: Color3,
	onToggle: (boolean) -> (),
	onColorChanged: (Color3) -> (),
	onColorPickerToggle: () -> (),
	LayoutOrder: number?,
	children: { [string]: any }?,
}

local function EffectRowBase(props: Props)
	local theme = StudioComponents.useTheme()
	local children: { [string]: any } = {}

	-- Header row: [checkbox + label cluster] ... [color swatch]
	-- leftCluster fills the row minus swatch + gap
	local swatchGap = 6
	local swatchReserve = Constants.TOOLBAR_ICON_GLYPH.X + swatchGap
	children["header"] = e("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
	}, {
		leftCluster = e("Frame", {
			Size = UDim2.new(1, -swatchReserve, 1, 0),
			BackgroundTransparency = 1,
		}, {
			layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6),
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			toggle = e(StudioComponents.Checkbox, {
				Value = props.enabled,
				OnChanged = function()
					props.onToggle(not props.enabled)
				end,
				LayoutOrder = 1,
			}),
			label = e(StudioComponents.Label, {
				Text = props.label,
				Size = UDim2.new(1, -22, 1, 0),
				LayoutOrder = 2,
			}),
		}),
		colorSwatch = e("TextButton", {
			Size = UDim2.fromOffset(Constants.TOOLBAR_ICON_GLYPH.X, Constants.TOOLBAR_ICON_GLYPH.Y),
			Position = UDim2.fromScale(1, 0.5),
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = props.color,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			[React.Event.MouseButton1Click] = props.onColorPickerToggle,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(0, 3) }),
			stroke = e("UIStroke", {
				Color = theme:GetColor(Enum.StudioStyleGuideColor.Border),
				Thickness = 1,
			}),
		}),
	})

	-- Merge in parameter rows from specific effect row components (shown only when enabled)
	if props.enabled and props.children then
		for k, v in pairs(props.children) do
			children[k] = v
		end
	end

	children["listLayout"] = e("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
	})

	return e("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
	}, children)
end

return EffectRowBase

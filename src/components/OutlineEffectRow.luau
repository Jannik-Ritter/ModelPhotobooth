local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)
local EffectRowBase = require(script.Parent.EffectRowBase)

local e = React.createElement

type Props = {
	enabled: boolean,
	color: Color3,
	thickness: number,
	onToggle: (boolean) -> (),
	onColorChanged: (Color3) -> (),
	onThicknessChanged: (number) -> (),
	onColorPickerToggle: () -> (),
	LayoutOrder: number?,
}

local function OutlineEffectRow(props: Props)
	return e(EffectRowBase, {
		label = "Outline",
		enabled = props.enabled,
		color = props.color,
		onToggle = props.onToggle,
		onColorChanged = props.onColorChanged,
		onColorPickerToggle = props.onColorPickerToggle,
		LayoutOrder = props.LayoutOrder,
	}, {
		-- Thickness: NumericInput already shows the value — no extra value label
		-- Layout: [Label 56px] [gap 6px] [NumericInput flex]
		thickness = e("Frame", {
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
			LayoutOrder = 2,
		}, {
			layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6),
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			label = e(StudioComponents.Label, {
				Text = "Thickness",
				Size = UDim2.new(0, 56, 1, 0),
				LayoutOrder = 1,
			}),
			input = e(StudioComponents.NumericInput, {
				Value = props.thickness,
				OnValidChanged = props.onThicknessChanged,
				Min = 1,
				Max = 8,
				Step = 1,
				Arrows = true,
				Size = UDim2.new(1, -62, 1, 0),
				LayoutOrder = 2,
			}),
		}),
	})
end

return OutlineEffectRow

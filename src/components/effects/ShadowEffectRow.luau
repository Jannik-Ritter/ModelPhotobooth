local Packages = script.Parent.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)
local EffectRowBase = require(script.Parent.EffectRowBase)

local e = React.createElement

type Props = {
	label: string,
	enabled: boolean,
	color: Color3,
	opacity: number,
	distance: number,
	blur: number,
	angle: number,
	onToggle: (boolean) -> (),
	onColorChanged: (Color3) -> (),
	onOpacityChanged: (number) -> (),
	onDistanceChanged: (number) -> (),
	onBlurChanged: (number) -> (),
	onAngleChanged: (number) -> (),
	onColorPickerToggle: () -> (),
	LayoutOrder: number?,
}

-- Slider rows: [Label 56px] [gap 6px] [Slider flex] [gap 6px] [Value 28px]
-- Slider width = UDim2.new(1, -96, 1, 0)  (56 + 6 + 6 + 28 = 96)
local function sliderRow(
	label: string,
	value: number,
	min: number,
	max: number,
	onChanged: (number) -> (),
	layoutOrder: number,
	valueSuffix: string?
)
	return e("Frame", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		LayoutOrder = layoutOrder,
	}, {
		layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		label = e(StudioComponents.Label, {
			Text = label,
			Size = UDim2.new(0, 56, 1, 0),
			LayoutOrder = 1,
		}),
		slider = e(StudioComponents.Slider, {
			Value = value,
			OnChanged = onChanged,
			Min = min,
			Max = max,
			Step = 1,
			Size = UDim2.new(1, -96, 1, 0),
			LayoutOrder = 2,
		}),
		value = e(StudioComponents.Label, {
			Text = tostring(math.floor(value)) .. (valueSuffix or ""),
			Size = UDim2.new(0, 28, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Right,
			LayoutOrder = 3,
		}),
	})
end

local function ShadowEffectRow(props: Props)
	return e(EffectRowBase, {
		label = props.label,
		enabled = props.enabled,
		color = props.color,
		onToggle = props.onToggle,
		onColorChanged = props.onColorChanged,
		onColorPickerToggle = props.onColorPickerToggle,
		LayoutOrder = props.LayoutOrder,
	}, {
		opacity = sliderRow("Opacity", props.opacity, 0, 100, props.onOpacityChanged, 2),
		distance = sliderRow("Distance", props.distance, 0, 30, props.onDistanceChanged, 3),
		blur = sliderRow("Blur", props.blur, 0, 12, props.onBlurChanged, 4),
		angle = sliderRow("Angle", props.angle, 0, 360, props.onAngleChanged, 5, "\u{00B0}"),
	})
end

return ShadowEffectRow

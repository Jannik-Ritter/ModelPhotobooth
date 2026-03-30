local Packages = script.Parent.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local EffectRowBase = require(script.Parent.EffectRowBase)
local SliderRow = require(script.Parent.SliderRow)

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
		opacity = e(SliderRow, {
			label = "Opacity",
			value = props.opacity,
			min = 0,
			max = 100,
			onChanged = props.onOpacityChanged,
			layoutOrder = 2,
		}),
		distance = e(SliderRow, {
			label = "Distance",
			value = props.distance,
			min = 0,
			max = 30,
			onChanged = props.onDistanceChanged,
			layoutOrder = 3,
		}),
		blur = e(SliderRow, {
			label = "Blur",
			value = props.blur,
			min = 0,
			max = 12,
			onChanged = props.onBlurChanged,
			layoutOrder = 4,
		}),
		angle = e(SliderRow, {
			label = "Angle",
			value = props.angle,
			min = 0,
			max = 360,
			onChanged = props.onAngleChanged,
			layoutOrder = 5,
			suffix = "\u{00B0}",
		}),
	})
end

return ShadowEffectRow

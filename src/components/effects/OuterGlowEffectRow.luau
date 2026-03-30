local Packages = script.Parent.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local EffectRowBase = require(script.Parent.EffectRowBase)
local SliderRow = require(script.Parent.SliderRow)

local e = React.createElement

type Props = {
	enabled: boolean,
	color: Color3,
	size: number,
	opacity: number,
	blur: number,
	onToggle: (boolean) -> (),
	onColorChanged: (Color3) -> (),
	onSizeChanged: (number) -> (),
	onOpacityChanged: (number) -> (),
	onBlurChanged: (number) -> (),
	onColorPickerToggle: () -> (),
	LayoutOrder: number?,
}

local function OuterGlowEffectRow(props: Props)
	return e(EffectRowBase, {
		label = "Glow",
		enabled = props.enabled,
		color = props.color,
		onToggle = props.onToggle,
		onColorChanged = props.onColorChanged,
		onColorPickerToggle = props.onColorPickerToggle,
		LayoutOrder = props.LayoutOrder,
	}, {
		size = e(SliderRow, {
			label = "Size",
			value = props.size,
			min = 0,
			max = 60,
			onChanged = props.onSizeChanged,
			layoutOrder = 2,
		}),
		opacity = e(SliderRow, {
			label = "Opacity",
			value = props.opacity,
			min = 0,
			max = 100,
			onChanged = props.onOpacityChanged,
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
	})
end

return OuterGlowEffectRow

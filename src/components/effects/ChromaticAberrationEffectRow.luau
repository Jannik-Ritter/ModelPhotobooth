local Packages = script.Parent.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)
local SliderRow = require(script.Parent.SliderRow)

local e = React.createElement

type Props = {
	enabled: boolean,
	distance: number,
	opacity: number,
	angle: number,
	onToggle: (boolean) -> (),
	onDistanceChanged: (number) -> (),
	onOpacityChanged: (number) -> (),
	onAngleChanged: (number) -> (),
	LayoutOrder: number?,
}

local function ChromaticAberrationEffectRow(props: Props)
	local children: { [string]: any } = {}

	children["listLayout"] = e("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
	})

	children["header"] = e("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
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
			Text = "Chromatic Aberration",
			Size = UDim2.new(1, -22, 1, 0),
			LayoutOrder = 2,
		}),
	})

	if props.enabled then
		children["distance"] = e(SliderRow, {
			label = "Distance",
			value = props.distance,
			min = 1,
			max = 50,
			onChanged = props.onDistanceChanged,
			layoutOrder = 2,
			suffix = "px",
		})
		children["opacity"] = e(SliderRow, {
			label = "Opacity",
			value = props.opacity,
			min = 0,
			max = 100,
			onChanged = props.onOpacityChanged,
			layoutOrder = 3,
			suffix = "%",
		})
		children["angle"] = e(SliderRow, {
			label = "Angle",
			value = props.angle,
			min = 0,
			max = 360,
			onChanged = props.onAngleChanged,
			layoutOrder = 4,
			suffix = "\u{00B0}",
		})
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
	}, children)
end

return ChromaticAberrationEffectRow

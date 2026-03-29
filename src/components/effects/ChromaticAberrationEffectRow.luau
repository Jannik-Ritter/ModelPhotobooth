local Packages = script.Parent.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

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

-- Slider rows: [Label 56px] [gap 6px] [Slider flex] [gap 6px] [Value 28px]
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
		children["distance"] = sliderRow("Distance", props.distance, 1, 50, props.onDistanceChanged, 2, "px")
		children["opacity"] = sliderRow("Opacity", props.opacity, 0, 100, props.onOpacityChanged, 3, "%")
		children["angle"] = sliderRow("Angle", props.angle, 0, 360, props.onAngleChanged, 4, "\u{00B0}")
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
	}, children)
end

return ChromaticAberrationEffectRow

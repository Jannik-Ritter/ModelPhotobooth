local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages._Index["jsdotlua_react@17.2.1"]["react"])
local StudioComponents = require(Packages.studiocomponents)

local e = React.createElement

type Props = {
	label: string,
	enabled: boolean,
	color: Color3,
	thickness: number?,
	opacity: number?,
	distance: number?,
	blur: number?,
	angle: number?,
	-- Callbacks
	onToggle: (boolean) -> (),
	onColorChanged: (Color3) -> (),
	onThicknessChanged: ((number) -> ())?,
	onOpacityChanged: ((number) -> ())?,
	onDistanceChanged: ((number) -> ())?,
	onBlurChanged: ((number) -> ())?,
	onAngleChanged: ((number) -> ())?,
	onColorPickerToggle: () -> (),
	LayoutOrder: number?,
}

local function EffectRow(props: Props)
	local theme = StudioComponents.useTheme()
	local children: { [string]: any } = {}

	-- Header row: [checkbox + label cluster] ... [color swatch]
	-- leftCluster fills the row minus 22px reserved for the swatch (16px) + gap (6px)
	children["header"] = e("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
	}, {
		leftCluster = e("Frame", {
			Size = UDim2.new(1, -22, 1, 0),
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
			Size = UDim2.fromOffset(16, 16),
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

	-- Parameter rows (only when enabled)
	if props.enabled then
		local paramOrder = 2

		-- Thickness: NumericInput already shows the value — no extra value label
		-- Layout: [Label 56px] [gap 6px] [NumericInput flex]
		if props.thickness ~= nil and props.onThicknessChanged then
			children["thickness"] = e("Frame", {
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundTransparency = 1,
				LayoutOrder = paramOrder,
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
			})
			paramOrder += 1
		end

		-- Slider rows: [Label 56px] [gap 6px] [Slider flex] [gap 6px] [Value 28px]
		-- Slider width = UDim2.new(1, -96, 1, 0)  (56 + 6 + 6 + 28 = 96)
		if props.opacity ~= nil and props.onOpacityChanged then
			children["opacity"] = e("Frame", {
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundTransparency = 1,
				LayoutOrder = paramOrder,
			}, {
				layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6),
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
				label = e(StudioComponents.Label, {
					Text = "Opacity",
					Size = UDim2.new(0, 56, 1, 0),
					LayoutOrder = 1,
				}),
				slider = e(StudioComponents.Slider, {
					Value = props.opacity,
					OnChanged = props.onOpacityChanged,
					Min = 0,
					Max = 100,
					Step = 1,
					Size = UDim2.new(1, -96, 1, 0),
					LayoutOrder = 2,
				}),
				value = e(StudioComponents.Label, {
					Text = tostring(math.floor(props.opacity)),
					Size = UDim2.new(0, 28, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Right,
					LayoutOrder = 3,
				}),
			})
			paramOrder += 1
		end

		if props.distance ~= nil and props.onDistanceChanged then
			children["distance"] = e("Frame", {
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundTransparency = 1,
				LayoutOrder = paramOrder,
			}, {
				layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6),
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
				label = e(StudioComponents.Label, {
					Text = "Distance",
					Size = UDim2.new(0, 56, 1, 0),
					LayoutOrder = 1,
				}),
				slider = e(StudioComponents.Slider, {
					Value = props.distance,
					OnChanged = props.onDistanceChanged,
					Min = 0,
					Max = 20,
					Step = 1,
					Size = UDim2.new(1, -96, 1, 0),
					LayoutOrder = 2,
				}),
				value = e(StudioComponents.Label, {
					Text = tostring(math.floor(props.distance)),
					Size = UDim2.new(0, 28, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Right,
					LayoutOrder = 3,
				}),
			})
			paramOrder += 1
		end

		if props.blur ~= nil and props.onBlurChanged then
			children["blur"] = e("Frame", {
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundTransparency = 1,
				LayoutOrder = paramOrder,
			}, {
				layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6),
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
				label = e(StudioComponents.Label, {
					Text = "Blur",
					Size = UDim2.new(0, 56, 1, 0),
					LayoutOrder = 1,
				}),
				slider = e(StudioComponents.Slider, {
					Value = props.blur,
					OnChanged = props.onBlurChanged,
					Min = 0,
					Max = 12,
					Step = 1,
					Size = UDim2.new(1, -96, 1, 0),
					LayoutOrder = 2,
				}),
				value = e(StudioComponents.Label, {
					Text = tostring(math.floor(props.blur)),
					Size = UDim2.new(0, 28, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Right,
					LayoutOrder = 3,
				}),
			})
			paramOrder += 1
		end

		if props.angle ~= nil and props.onAngleChanged then
			children["angle"] = e("Frame", {
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundTransparency = 1,
				LayoutOrder = paramOrder,
			}, {
				layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6),
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
				label = e(StudioComponents.Label, {
					Text = "Angle",
					Size = UDim2.new(0, 56, 1, 0),
					LayoutOrder = 1,
				}),
				slider = e(StudioComponents.Slider, {
					Value = props.angle,
					OnChanged = props.onAngleChanged,
					Min = 0,
					Max = 360,
					Step = 1,
					Size = UDim2.new(1, -96, 1, 0),
					LayoutOrder = 2,
				}),
				value = e(StudioComponents.Label, {
					Text = tostring(math.floor(props.angle)) .. "\u{00B0}",
					Size = UDim2.new(0, 28, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Right,
					LayoutOrder = 3,
				}),
			})
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

return EffectRow

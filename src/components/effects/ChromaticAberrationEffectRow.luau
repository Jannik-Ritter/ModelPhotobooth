local Packages = script.Parent.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local e = React.createElement

type Props = {
	enabled: boolean,
	amount: number,
	onToggle: (boolean) -> (),
	onAmountChanged: (number) -> (),
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

	-- Amount slider (only when enabled)
	-- Slider rows: [Label 56px] [gap 6px] [Slider flex] [gap 6px] [Value 28px]
	if props.enabled then
		children["amount"] = e("Frame", {
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
				Text = "Amount",
				Size = UDim2.new(0, 56, 1, 0),
				LayoutOrder = 1,
			}),
			slider = e(StudioComponents.Slider, {
				Value = props.amount,
				OnChanged = props.onAmountChanged,
				Min = 1,
				Max = 50,
				Step = 1,
				Size = UDim2.new(1, -96, 1, 0),
				LayoutOrder = 2,
			}),
			value = e(StudioComponents.Label, {
				Text = tostring(math.floor(props.amount)) .. "px",
				Size = UDim2.new(0, 28, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Right,
				LayoutOrder = 3,
			}),
		})
	end

	return e("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
	}, children)
end

return ChromaticAberrationEffectRow

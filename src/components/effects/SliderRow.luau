local Packages = script.Parent.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local e = React.createElement

export type Props = {
	label: string,
	value: number,
	min: number,
	max: number,
	step: number?,      -- default 1; also controls rounding on commit
	decimals: number?,  -- decimal places to display (default 0)
	onChanged: (number) -> (),
	layoutOrder: number,
	suffix: string?,    -- shown after the number when not editing (e.g. "°", "%", "px")
	labelWidth: number?,  -- default 56
	valueWidth: number?,  -- default 28
}

local function SliderRow(props: Props)
	local theme = StudioComponents.useTheme()
	local editText, setEditText = React.useState(nil :: string?)

	local step = props.step or 1
	local decimals = props.decimals or 0
	local labelWidth = props.labelWidth or 56
	local valueWidth = props.valueWidth or 28
	local isEditing = editText ~= nil

	local formattedValue = if decimals > 0
		then string.format("%." .. decimals .. "f", props.value) .. (props.suffix or "")
		else tostring(math.round(props.value)) .. (props.suffix or "")

	local function commit(text: string)
		local n = tonumber(text)
		if n then
			n = math.round(n / step) * step
			n = math.clamp(n, props.min, props.max)
			props.onChanged(n)
		end
		setEditText(nil)
	end

	return e("Frame", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder,
	}, {
		layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		label = e(StudioComponents.Label, {
			Text = props.label,
			Size = UDim2.new(0, labelWidth, 1, 0),
			LayoutOrder = 1,
		}),
		slider = e(StudioComponents.Slider, {
			Value = props.value,
			OnChanged = props.onChanged,
			Min = props.min,
			Max = props.max,
			Step = step,
			Size = UDim2.new(1, -(labelWidth + valueWidth + 12), 1, 0),
			LayoutOrder = 2,
		}),
		valueBox = e("TextBox", {
			Text = if isEditing then editText else formattedValue,
			Size = UDim2.new(0, valueWidth, 1, 0),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground),
			BackgroundTransparency = if isEditing then 0 else 1,
			BorderSizePixel = 0,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
			TextSize = 13,
			Font = Enum.Font.SourceSans,
			TextXAlignment = Enum.TextXAlignment.Center,
			ClearTextOnFocus = false,
			LayoutOrder = 3,
			[React.Event.Focused] = function()
				local initial = if decimals > 0
					then string.format("%." .. decimals .. "f", props.value)
					else tostring(math.round(props.value))
				setEditText(initial)
			end,
			[React.Event.FocusLost] = function(rbx)
				commit(rbx.Text)
			end,
		}, {
			corner = if isEditing
				then e("UICorner", { CornerRadius = UDim.new(0, 2) })
				else nil,
		}),
	})
end

return SliderRow

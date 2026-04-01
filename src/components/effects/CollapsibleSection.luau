local Packages = script.Parent.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local Constants = require(script.Parent.Parent.Parent.Constants)

local e = React.createElement

type Props = {
	title: string,
	collapsed: boolean,
	onToggle: () -> (),
	children: any,
	LayoutOrder: number?,
}

local function CollapsibleSection(props: Props)
	local theme = StudioComponents.useTheme()
	local hovered, setHovered = React.useState(false)

	local headerBg = if hovered
		then theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Hover)
		else theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)

	local children: { [string]: any } = {}

	children["header"] = e("TextButton", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = headerBg,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = 0,
		[React.Event.Activated] = props.onToggle,
		[React.Event.MouseEnter] = function()
			setHovered(true)
		end,
		[React.Event.MouseLeave] = function()
			setHovered(false)
		end,
	}, {
		corner = e("UICorner", { CornerRadius = UDim.new(0, Constants.CORNER_RADIUS_4) }),
		padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, Constants.PADDING_8),
			PaddingRight = UDim.new(0, Constants.PADDING_8),
		}),
		chevron = e("TextLabel", {
			Text = if props.collapsed then "\u{25B6}" else "\u{25BC}",
			Size = UDim2.new(0, 14, 1, 0),
			BackgroundTransparency = 1,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
			TextSize = 10,
			Font = Enum.Font.SourceSans,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		title = e("TextLabel", {
			Text = props.title,
			Size = UDim2.new(1, -14, 1, 0),
			Position = UDim2.fromOffset(14, 0),
			BackgroundTransparency = 1,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
			TextSize = 14,
			Font = Enum.Font.SourceSansSemibold,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})

	if not props.collapsed then
		children["content"] = e("Frame", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {
			padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, Constants.PADDING_8),
				PaddingRight = UDim.new(0, Constants.PADDING_8),
				PaddingTop = UDim.new(0, Constants.PADDING_8),
				PaddingBottom = UDim.new(0, Constants.PADDING_8),
			}),
			layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = Constants.LIST_PADDING_SMALL,
			}),
			children = React.createElement(React.Fragment, nil, props.children),
		})
	end

	children["listLayout"] = e("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = Constants.GROUP_PADDING,
	})

	return e("Frame", {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
	}, children)
end

return CollapsibleSection

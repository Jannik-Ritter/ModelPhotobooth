local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages._Index["jsdotlua_react@17.2.1"]["react"])
local StudioComponents = require(Packages.studiocomponents)

local e = React.createElement

type Props = {
	statusText: string,
	capturing: boolean,
	onCapture: () -> (),
	onExport: () -> (),
	captureDisabled: boolean,
	exportDisabled: boolean,
}

local function ToolbarStrip(props: Props)
	local theme = StudioComponents.useTheme()

	local statusContent = e(StudioComponents.Label, {
		Text = props.statusText,
		Size = UDim2.new(1, -180, 1, 0),
		Position = UDim2.fromOffset(10, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	return e("Frame", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Titlebar),
		BorderSizePixel = 0,
	}, {
		borderBottom = e("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 1, -1),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
			BorderSizePixel = 0,
			ZIndex = 2,
		}),
		status = statusContent,
		buttons = e("Frame", {
			Size = UDim2.new(0, 170, 1, 0),
			Position = UDim2.new(1, -170, 0, 0),
			BackgroundTransparency = 1,
		}, {
			layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6),
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
			}),
			padding = e("UIPadding", {
				PaddingRight = UDim.new(0, 8),
			}),
			capture = e(StudioComponents.Button, {
				Text = "Capture Selected",
				OnActivated = props.onCapture,
				Disabled = props.captureDisabled or props.capturing,
				Size = UDim2.new(0, 100, 0, 24),
				LayoutOrder = 1,
			}),
			export = e(StudioComponents.MainButton, {
				Text = "Export",
				OnActivated = props.onExport,
				Disabled = props.exportDisabled,
				Size = UDim2.new(0, 60, 0, 24),
				LayoutOrder = 2,
			}),
		}),
	})
end

return ToolbarStrip

local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages._Index["jsdotlua_react@17.2.1"]["react"])
local StudioComponents = require(Packages.studiocomponents)

local e = React.createElement

type Props = {
	capturing: boolean,
	onCapture: () -> (),
	onCaptureAll: () -> (),
	onExport: () -> (),
	captureDisabled: boolean,
	captureAllDisabled: boolean,
	exportDisabled: boolean,
}

local function ToolbarStrip(props: Props)
	local theme = StudioComponents.useTheme()

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
		buttons = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, {
			layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6),
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
			}),
			padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 8),
			}),
			capture = e(StudioComponents.Button, {
				Text = "Capture Selected",
				OnActivated = props.onCapture,
				Disabled = props.captureDisabled or props.capturing,
				Size = UDim2.fromOffset(112, 24),
				LayoutOrder = 1,
			}),
			captureAll = e(StudioComponents.Button, {
				Text = "Capture All",
				OnActivated = props.onCaptureAll,
				Disabled = props.captureAllDisabled or props.capturing,
				Size = UDim2.fromOffset(82, 24),
				LayoutOrder = 2,
			}),
			export = e(StudioComponents.MainButton, {
				Text = "Export All",
				OnActivated = props.onExport,
				Disabled = props.exportDisabled,
				Size = UDim2.fromOffset(76, 24),
				LayoutOrder = 3,
			}),
		}),
	})
end

return ToolbarStrip

local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local constants = require(script.Parent.Parent.constants)

local e = React.createElement

type Props = {
	rendering: boolean,
	onRender: () -> (),
	onRenderAll: () -> (),
	onExport: () -> (),
	onUploadAll: () -> (),
	onHelp: () -> (),
	renderDisabled: boolean,
	renderAllDisabled: boolean,
	exportDisabled: boolean,
	uploadAllDisabled: boolean,
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
			render = e(StudioComponents.Button, {
				Text = "Render Selected",
				OnActivated = props.onRender,
				Disabled = props.renderDisabled or props.rendering,
				Size = UDim2.fromOffset(112, 24),
				LayoutOrder = 1,
			}),
			renderAll = e(StudioComponents.Button, {
				Text = "Render All",
				OnActivated = props.onRenderAll,
				Disabled = props.renderAllDisabled or props.rendering,
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
			uploadAll = e(StudioComponents.MainButton, {
				Text = "Upload All",
				OnActivated = props.onUploadAll,
				Disabled = props.uploadAllDisabled,
				Size = UDim2.fromOffset(76, 24),
				LayoutOrder = 4,
			}),
			help = e(StudioComponents.Button, {
				OnActivated = props.onHelp,
				Icon = {
					Image = "rbxassetid://101420100842394",
					Size = constants.TOOLBAR_ICON_GLYPH,
					UseThemeColor = true,
				},
				Size = UDim2.fromOffset(24, 24),
				LayoutOrder = 5,
			}),
		}),
	})
end

return ToolbarStrip

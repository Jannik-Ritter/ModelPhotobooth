local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local StoreContext = require(script.Parent.Parent.StoreContext)
local constants = require(script.Parent.Parent.constants)

local e = React.createElement

type Props = {
	onRender: () -> (),
	onRenderAll: () -> (),
	onExport: () -> (),
	onUploadAll: () -> (),
	onHelp: () -> (),
}

local function ToolbarStrip(props: Props)
	local store = StoreContext.useStore()
	local state = store.state
	local theme = StudioComponents.useTheme()

	local totalCount = 0
	for _, entry in ipairs(state.models) do
		if not entry.isExported then
			totalCount += 1
		end
	end

	local hasRenders = false
	for _, entry in ipairs(state.models) do
		if entry.image then
			hasRenders = true
			break
		end
	end

	local hasRenderableSelected = false
	for _, idx in ipairs(state.selectedModelIndices) do
		local entry = state.models[idx]
		if entry and not entry.isExported then
			hasRenderableSelected = true
			break
		end
	end

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
				Disabled = not hasRenderableSelected or state.rendering,
				Size = UDim2.fromOffset(112, 24),
				LayoutOrder = 1,
			}),
			renderAll = e(StudioComponents.Button, {
				Text = "Render All",
				OnActivated = props.onRenderAll,
				Disabled = totalCount == 0 or state.rendering,
				Size = UDim2.fromOffset(82, 24),
				LayoutOrder = 2,
			}),
			export = e(StudioComponents.MainButton, {
				Text = "Export All",
				OnActivated = props.onExport,
				Disabled = not hasRenders,
				Size = UDim2.fromOffset(76, 24),
				LayoutOrder = 3,
			}),
			uploadAll = e(StudioComponents.MainButton, {
				Text = "Upload All",
				OnActivated = props.onUploadAll,
				Disabled = not hasRenders,
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

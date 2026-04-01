local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local StoreContext = require(script.Parent.Parent.StoreContext)
local Constants = require(script.Parent.Parent.Constants)

local e = React.createElement

type Props = {
	onRender: () -> (),
	onRenderAll: () -> (),
	onExport: () -> (),
	onExportSelected: () -> (),
	onUploadAll: () -> (),
	onHelp: () -> (),
}

local function ToolbarStrip(props: Props)
	local store = StoreContext.useStore()
	local state = store.state
	local theme = StudioComponents.useTheme()

	local totalCount, hasRenders, hasRenderableSelected, hasSelectedWithRenders = React.useMemo(function()
		local count = 0
		local anyRenders = false
		local renderableSelected = false
		local selectedWithRenders = false
		for _, entry in ipairs(state.models) do
			if not entry.isExported then
				count += 1
			end
			if entry.image then
				anyRenders = true
			end
		end
		for _, idx in ipairs(state.selectedModelIndices) do
			local entry = state.models[idx]
			if entry then
				if not entry.isExported then
					renderableSelected = true
				end
				if entry.image then
					selectedWithRenders = true
				end
			end
		end
		return count, anyRenders, renderableSelected, selectedWithRenders
	end, { state.models, state.selectedModelIndices } :: { any })

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
				Padding = Constants.LIST_PADDING,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
			}),
			padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, Constants.PADDING_8),
			}),
			render = e(StudioComponents.Button, {
				Text = "Render Selected",
				OnActivated = props.onRender,
				Disabled = not hasRenderableSelected or state.rendering,
				Size = UDim2.fromOffset(112, Constants.BUTTON_HEIGHT),
				LayoutOrder = 1,
			}),
			renderAll = e(StudioComponents.Button, {
				Text = "Render All",
				OnActivated = props.onRenderAll,
				Disabled = totalCount == 0 or state.rendering,
				Size = UDim2.fromOffset(82, Constants.BUTTON_HEIGHT),
				LayoutOrder = 2,
			}),
			exportSelected = e(StudioComponents.MainButton, {
				Text = "Export Selected",
				OnActivated = props.onExportSelected,
				Disabled = not hasSelectedWithRenders,
				Size = UDim2.fromOffset(108, Constants.BUTTON_HEIGHT),
				LayoutOrder = 3,
			}),
			export = e(StudioComponents.MainButton, {
				Text = "Export All",
				OnActivated = props.onExport,
				Disabled = not hasRenders,
				Size = UDim2.fromOffset(76, Constants.BUTTON_HEIGHT),
				LayoutOrder = 4,
			}),
			uploadAll = e(StudioComponents.MainButton, {
				Text = "Upload All",
				OnActivated = props.onUploadAll,
				Disabled = not hasRenders,
				Size = UDim2.fromOffset(76, Constants.BUTTON_HEIGHT),
				LayoutOrder = 5,
			}),
			help = e(StudioComponents.Button, {
				OnActivated = props.onHelp,
				Icon = {
					Image = "rbxassetid://101420100842394",
					Size = Constants.TOOLBAR_ICON_GLYPH,
					UseThemeColor = true,
				},
				Size = UDim2.fromOffset(24, Constants.BUTTON_HEIGHT),
				LayoutOrder = 6,
			}),
		}),
	})
end

return ToolbarStrip

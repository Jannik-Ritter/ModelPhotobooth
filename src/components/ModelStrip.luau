local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local StoreContext = require(script.Parent.Parent.StoreContext)
local ModelThumb = require(script.Parent.ModelThumb)
local Constants = require(script.Parent.Parent.Constants)

local e = React.createElement

type Props = {
	onSelectModel: (index: number) -> (),
	onPreviewModel: (index: number) -> (),
}

-- Bottom strip: same chrome as ToolbarStrip; Studio Label / ScrollFrame for content.
local function ModelStrip(props: Props)
	local store = StoreContext.useStore()
	local state = store.state
	local theme = StudioComponents.useTheme()
	local stripHeight, setStripHeight = React.useState(Constants.STRIP_DEFAULT_HEIGHT)

	-- thumbSize fills the strip height minus top/bottom padding
	local thumbSize = math.max(Constants.THUMB_MIN_SIZE, stripHeight - Constants.STRIP_PADDING_V * 2)

	local onAbsoluteSize = function(rbx: Frame)
		local h = math.floor(rbx.AbsoluteSize.Y)
		if h ~= stripHeight then
			setStripHeight(h)
		end
	end

	local stripRoot = {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Titlebar),
		BorderSizePixel = 0,
		[React.Change.AbsoluteSize] = onAbsoluteSize,
	}

	if #state.models == 0 then
		return e("Frame", stripRoot, {
			label = e(StudioComponents.Label, {
				Text = "Select models in Explorer",
				Size = UDim2.fromScale(1, 1),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}),
		})
	end

	local selectedSet: { [number]: boolean } = {}
	for _, idx in ipairs(state.selectedModelIndices) do
		selectedSet[idx] = true
	end

	local thumbs = {}
	for i, entry in ipairs(state.models) do
		-- Key by model identity (not index) so list compaction does not recycle a thumb's internal
		-- viewport state onto a different model when selection order changes.
		local thumbKey = "thumb_" .. entry.instance:GetDebugId(0)
		thumbs[thumbKey] = e(ModelThumb, {
			entry = entry,
			thumbSize = thumbSize,
			isActive = selectedSet[i] == true,
			onSelect = function()
				props.onSelectModel(i)
			end,
			onPreview = function()
				props.onPreviewModel(i)
			end,
			LayoutOrder = i,
		})
	end

	return e("Frame", stripRoot, {
		scroll = e(StudioComponents.ScrollFrame, {
			Size = UDim2.fromScale(1, 1),
			ScrollingDirection = Enum.ScrollingDirection.X,
			Layout = {
				ClassName = "UIListLayout",
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = Constants.LIST_PADDING,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			},
			PaddingLeft = UDim.new(0, Constants.PADDING_8),
			PaddingRight = UDim.new(0, Constants.PADDING_8),
			PaddingTop = UDim.new(0, Constants.STRIP_PADDING_V),
			PaddingBottom = UDim.new(0, Constants.STRIP_PADDING_V),
		}, thumbs),
	})
end

return ModelStrip

local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local Store = require(script.Parent.Parent.Store)
local ModelThumb = require(script.Parent.ModelThumb)

local e = React.createElement

local PADDING_V = 6 -- PaddingTop + PaddingBottom each

type Props = {
	models: { Store.ModelEntry },
	selectedModelIndices: { number },
	yaw: number,
	pitch: number,
	roll: number,
	fov: number,
	cameraDistance: number,
	offsetX: number,
	offsetY: number,
	offsetZ: number,
	onSelectModel: (index: number) -> (),
	onPreviewModel: (index: number) -> (),
}

-- Bottom strip: same chrome as ToolbarStrip; Studio Label / ScrollFrame for content.
local function ModelStrip(props: Props)
	local theme = StudioComponents.useTheme()
	local stripHeight, setStripHeight = React.useState(80)

	-- thumbSize fills the strip height minus top/bottom padding
	local thumbSize = math.max(20, stripHeight - PADDING_V * 2)

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

	if #props.models == 0 then
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
	for _, idx in ipairs(props.selectedModelIndices) do
		selectedSet[idx] = true
	end

	local thumbs = {}
	for i, entry in ipairs(props.models) do
		thumbs["thumb_" .. i] = e(ModelThumb, {
			entry = entry,
			thumbSize = thumbSize,
			yaw = props.yaw,
			pitch = props.pitch,
			roll = props.roll,
			fov = props.fov,
			cameraDistance = props.cameraDistance,
			offsetX = props.offsetX,
			offsetY = props.offsetY,
			offsetZ = props.offsetZ,
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
				Padding = UDim.new(0, 6),
				VerticalAlignment = Enum.VerticalAlignment.Center,
			},
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, PADDING_V),
			PaddingBottom = UDim.new(0, PADDING_V),
		}, thumbs),
	})
end

return ModelStrip

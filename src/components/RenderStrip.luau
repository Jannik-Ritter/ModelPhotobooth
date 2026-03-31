local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local Store = require(script.Parent.Parent.Store)
local RenderThumb = require(script.Parent.RenderThumb)

local e = React.createElement

local PADDING_V = 9

type Props = {
	renderHistory: { Store.RenderHistoryEntry },
	previewHistoryIndex: number?,
	onPreviewRender: (index: number) -> (),
}

local function RenderStrip(props: Props)
	local theme = StudioComponents.useTheme()
	local stripHeight, setStripHeight = React.useState(80)

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

	if #props.renderHistory == 0 then
		return e("Frame", stripRoot, {
			label = e(StudioComponents.Label, {
				Text = "No renders yet",
				Size = UDim2.fromScale(1, 1),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}),
		})
	end

	local thumbs = {}
	for i, entry in ipairs(props.renderHistory) do
		local thumbKey = "rthumb_" .. tostring(i)
		thumbs[thumbKey] = e(RenderThumb, {
			entry = entry,
			thumbSize = thumbSize,
			isActive = props.previewHistoryIndex == i,
			onPreview = function()
				props.onPreviewRender(i)
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

return RenderStrip

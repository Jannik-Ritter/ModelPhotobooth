local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages._Index["jsdotlua_react@17.2.1"]["react"])
local StudioComponents = require(Packages.studiocomponents)

local Store = require(script.Parent.Parent.Store)
local ModelThumb = require(script.Parent.ModelThumb)

local e = React.createElement

type Props = {
	models: { Store.ModelEntry },
	selectedModelIndices: { number },
	yaw: number,
	pitch: number,
	fov: number,
	onSelectModel: (index: number) -> (),
	onPreviewModel: (index: number) -> (),
}

local function ModelStrip(props: Props)
	local theme = StudioComponents.useTheme()

	if #props.models == 0 then
		return e("Frame", {
			Size = UDim2.new(1, -220, 0, 96),
			Position = UDim2.new(0, 0, 1, -96),
			BackgroundTransparency = 1,
		}, {
			border = e("Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
				BorderSizePixel = 0,
			}),
			label = e(StudioComponents.Label, {
				Text = "Select models in Explorer",
				Size = UDim2.fromScale(1, 1),
				TextXAlignment = Enum.TextXAlignment.Center,
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
			yaw = props.yaw,
			pitch = props.pitch,
			fov = props.fov,
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

	return e("Frame", {
		Size = UDim2.new(1, -220, 0, 96),
		Position = UDim2.new(0, 0, 1, -96),
		BackgroundTransparency = 1,
	}, {
		border = e("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
			BorderSizePixel = 0,
			ZIndex = 2,
		}),
		scroll = e(StudioComponents.ScrollFrame, {
			Size = UDim2.new(1, 0, 1, -1),
			Position = UDim2.new(0, 0, 0, 1),
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
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
		}, thumbs),
	})
end

return ModelStrip

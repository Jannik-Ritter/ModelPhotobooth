local Packages = script.Parent.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local Darkener = require(script.Parent.Darkener)
local ModalCloseButton = require(script.Parent.ModalCloseButton)

local e = React.createElement

export type UploadResult = {
	name: string,
	assetId: number?,
	image: EditableImage?,
}

type Props = {
	results: { UploadResult },
	onClose: () -> (),
	onHelp: (() -> ())?,
}

-- Panel: 420px wide. With 8px padding each side, content width = 404px.
-- Row layout (absolute, 48px tall):
--   thumb=40 | gap=8 | name=128 | gap=8 | idBox=160 | gap=8 | copy=52  = 404px
-- Failed row replaces idBox+gap+copy with a single "Failed" label (220px wide).
local PANEL_W = 420
local ROW_H = 48
local THUMB_W = 40
local NAME_W = 128
local ID_W = 160
local COPY_W = 52
local GAP = 8
local PAD = 8

local function ResultRow(props: UploadResult & { LayoutOrder: number })
	local theme = StudioComponents.useTheme()
	local textBoxRef = React.useRef(nil)
	local idText = if props.assetId then "rbxassetid://" .. tostring(props.assetId) else nil

	local function onCopy()
		local tb = textBoxRef.current
		if not tb then
			return
		end
		tb:CaptureFocus()
		tb.CursorPosition = #tb.Text + 1
		tb.SelectionStart = 1
	end

	local nameX = THUMB_W + GAP
	local rightX = nameX + NAME_W + GAP
	local rightW = ID_W + GAP + COPY_W -- 220px, fills rest of row for failed case

	return e("Frame", {
		Size = UDim2.new(1, 0, 0, ROW_H),
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
	}, {
		thumbnail = e("ImageLabel", {
			--ImageContent = Content.fromObject(props.image),
			Image = idText,
			Size = UDim2.fromOffset(THUMB_W, THUMB_W),
			Position = UDim2.fromOffset(0, (ROW_H - THUMB_W) / 2),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground),
			BorderSizePixel = 0,
			ScaleType = Enum.ScaleType.Fit,
		}),
		nameLabel = e("TextLabel", {
			Text = props.name,
			Size = UDim2.fromOffset(NAME_W, ROW_H),
			Position = UDim2.fromOffset(nameX, 0),
			BackgroundTransparency = 1,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
			TextSize = 13,
			Font = Enum.Font.SourceSans,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}),
		idBox = if idText
			then e("TextBox", {
				Text = idText,
				Size = UDim2.fromOffset(ID_W, 22),
				Position = UDim2.fromOffset(rightX, (ROW_H - 22) / 2),
				BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground),
				BorderSizePixel = 0,
				TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
				TextSize = 11,
				Font = Enum.Font.SourceSans,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextEditable = false,
				ClearTextOnFocus = false,
				ClipsDescendants = true,
				ref = textBoxRef,
				[React.Event.Focused] = function(rbx)
					rbx.CursorPosition = #rbx.Text + 1
					rbx.SelectionStart = 1
				end,
			}, {
				padding = e("UIPadding", {
					PaddingLeft = UDim.new(0, 4),
					PaddingRight = UDim.new(0, 4),
				}),
			})
			else e("TextLabel", {
				Text = "Failed",
				Size = UDim2.fromOffset(rightW, ROW_H),
				Position = UDim2.fromOffset(rightX, 0),
				BackgroundTransparency = 1,
				TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ErrorText),
				TextSize = 13,
				Font = Enum.Font.SourceSans,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
		copyButton = if idText
			then e(StudioComponents.Button, {
				Text = "Copy",
				OnActivated = onCopy,
				Size = UDim2.fromOffset(COPY_W, 22),
				Position = UDim2.fromOffset(rightX + ID_W + GAP, (ROW_H - 22) / 2),
			})
			else nil,
	})
end

local function UploadResultModal(props: Props)
	local theme = StudioComponents.useTheme()

	local hasFailed = false
	for _, result in ipairs(props.results) do
		if result.assetId == nil then
			hasFailed = true
			break
		end
	end

	-- Body height: up to 5 rows visible, then scrolls
	local rowSpacing = ROW_H + 6
	local bodyHeight = math.min(#props.results * rowSpacing + 6, 5 * rowSpacing + 6)
	local footerHeight = if hasFailed and props.onHelp then 36 else 0

	local rows: { [string]: any } = {
		layout = e("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		}),
		padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, PAD),
			PaddingRight = UDim.new(0, PAD),
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
		}),
	}
	for i, result in ipairs(props.results) do
		rows["row_" .. tostring(i)] = e(ResultRow, {
			name = result.name,
			assetId = result.assetId,
			image = result.image,
			LayoutOrder = i,
		})
	end

	-- 32 title + 26 hint + bodyHeight [+ footerHeight]
	return e(Darkener, {
		onBackdropClick = function() end,
	}, {
		panel = e("Frame", {
			Size = UDim2.fromOffset(PANEL_W, 32 + 26 + bodyHeight + footerHeight),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
			BorderSizePixel = 0,
			Active = true,
			ClipsDescendants = true,
		}, {
			titleBar = e("Frame", {
				Size = UDim2.new(1, 0, 0, 32),
				BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Titlebar),
				BorderSizePixel = 0,
			}, {
				border = e("Frame", {
					Size = UDim2.new(1, 0, 0, 1),
					Position = UDim2.new(0, 0, 1, -1),
					BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
					BorderSizePixel = 0,
				}),
				title = e("TextLabel", {
					Text = "Upload Complete",
					Size = UDim2.new(1, -40, 1, 0),
					Position = UDim2.fromOffset(10, 0),
					BackgroundTransparency = 1,
					TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
					TextSize = 13,
					Font = Enum.Font.SourceSans,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				close = e(ModalCloseButton, {
					onActivated = props.onClose,
				}),
			}),
			hint = e("TextLabel", {
				Text = "Click Copy to select an ID, then press Ctrl+C",
				Size = UDim2.new(1, 0, 0, 26),
				Position = UDim2.fromOffset(0, 32),
				BackgroundTransparency = 1,
				TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.SubText),
				TextSize = 11,
				Font = Enum.Font.SourceSans,
				TextXAlignment = Enum.TextXAlignment.Center,
			}),
			body = e("ScrollingFrame", {
				Size = UDim2.fromOffset(PANEL_W, bodyHeight),
				Position = UDim2.fromOffset(0, 58),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollBarThickness = 6,
				ScrollBarImageColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ScrollBar),
				ScrollingDirection = Enum.ScrollingDirection.Y,
			}, rows),
			footer = if footerHeight > 0
				then e("Frame", {
					Size = UDim2.fromOffset(PANEL_W, footerHeight),
					Position = UDim2.fromOffset(0, 58 + bodyHeight),
					BackgroundTransparency = 1,
				}, {
					border = e("Frame", {
						Size = UDim2.new(1, 0, 0, 1),
						BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
						BorderSizePixel = 0,
					}),
					helpBtn = e(StudioComponents.Button, {
						Text = "Open Common Issues",
						Size = UDim2.fromOffset(140, 22),
						Position = UDim2.fromScale(0.5, 0.5),
						AnchorPoint = Vector2.new(0.5, 0.5),
						OnActivated = props.onHelp,
					}),
				})
				else nil,
		}),
	})
end

return UploadResultModal

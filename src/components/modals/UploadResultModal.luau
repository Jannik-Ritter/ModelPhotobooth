local Packages = script.Parent.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local Darkener = require(script.Parent.Darkener)
local ModalCloseButton = require(script.Parent.ModalCloseButton)

local e = React.createElement

export type UploadResult = {
	name: string,
	assetId: number?,
}

type Props = {
	results: { UploadResult },
	onClose: () -> (),
}

-- Panel is 380px wide. With 8px padding each side, content width = 364px.
-- Row layout (absolute): name=140px | gap=8 | idBox=156px | gap=8 | copy=52px = 364px
local ROW_H = 30
local NAME_W = 140
local ID_W = 156
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

	return e("Frame", {
		Size = UDim2.new(1, 0, 0, ROW_H),
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
	}, {
		nameLabel = e("TextLabel", {
			Text = props.name,
			Size = UDim2.fromOffset(NAME_W, ROW_H),
			Position = UDim2.fromOffset(0, 0),
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
				Size = UDim2.fromOffset(ID_W, ROW_H - 6),
				Position = UDim2.fromOffset(NAME_W + GAP, 3),
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
				Size = UDim2.fromOffset(ID_W + GAP + COPY_W, ROW_H),
				Position = UDim2.fromOffset(NAME_W + GAP, 0),
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
				Size = UDim2.fromOffset(COPY_W, ROW_H - 6),
				Position = UDim2.fromOffset(NAME_W + GAP + ID_W + GAP, 3),
			})
			else nil,
	})
end

local function UploadResultModal(props: Props)
	local theme = StudioComponents.useTheme()

	-- Body height: up to 6 rows visible, then scrolls
	local rowSpacing = ROW_H + 6
	local bodyHeight = math.min(#props.results * rowSpacing + 6, 6 * rowSpacing + 6)

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
			LayoutOrder = i,
		})
	end

	return e(Darkener, {
		onBackdropClick = function() end,
	}, {
		panel = e("Frame", {
			Size = UDim2.fromOffset(380, 32 + bodyHeight),
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
			body = e("ScrollingFrame", {
				Size = UDim2.new(1, 0, 1, -32),
				Position = UDim2.fromOffset(0, 32),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollBarThickness = 6,
				ScrollBarImageColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ScrollBar),
				ScrollingDirection = Enum.ScrollingDirection.Y,
			}, rows),
		}),
	})
end

return UploadResultModal

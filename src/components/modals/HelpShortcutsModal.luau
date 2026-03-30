local Packages = script.Parent.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local Darkener = require(script.Parent.Darkener)
local ModalCloseButton = require(script.Parent.ModalCloseButton)

local e = React.createElement

type Props = {
	onClose: () -> (),
}

local ROW_HEIGHT = 22
local SECTION_GAP = 10

local HEADING_TEXT_SIZE = 18
local SECTION_TEXT_SIZE = 17
local CONTENT_TEXT_SIZE = 16

local function sectionHeader(theme, text: string, layoutOrder: number)
	return e("TextLabel", {
		Text = text,
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.SubText),
		TextSize = SECTION_TEXT_SIZE,
		Font = Enum.Font.SourceSansSemibold,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = layoutOrder,
	})
end

local function guideText(theme, layoutOrder: number)
	return e("TextLabel", {
		Text = table.concat({
			"Select a model or part in the Explorer. It shows up in the strip under the preview. ",
			"The right panel holds camera, effects, animation, and export settings. Presets save those settings.",
			"Use the preview controls to render, then Export to place the result in Workspace. ",
			"To view a render before exporting, click on the icon on the model strip. ",
			'Then Simply right-click the exported results and select "Export as OBJ" to export the image(s). ',
		}, ""),
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
		TextSize = CONTENT_TEXT_SIZE,
		Font = Enum.Font.SourceSans,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		LayoutOrder = layoutOrder,
	})
end

local function shortcutRow(keys: string, description: string, layoutOrder: number)
	return e("Frame", {
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		BackgroundTransparency = 1,
		LayoutOrder = layoutOrder,
	}, {
		layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 12),
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		keyCol = e(StudioComponents.Label, {
			Text = keys,
			Size = UDim2.new(0, 150, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		desc = e(StudioComponents.Label, {
			Text = description,
			TextWraps = true,
			Size = UDim2.new(1, -162, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}),
	})
end

local function HelpShortcutsModal(props: Props)
	local theme = StudioComponents.useTheme()

	-- Title 32 + scroll 220 (backdrop does not dismiss; only titlebar close)
	return e(Darkener, {
		onBackdropClick = function() end,
		ZIndex = 10001,
	}, {
		panel = e("Frame", {
			Size = UDim2.fromOffset(420, 320),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
			BorderSizePixel = 0,
			Active = true,
		}, {
			layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 3),
			}),

			titleBar = e("Frame", {
				Size = UDim2.new(1, 0, 0, 32),
				BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Titlebar),
				BorderSizePixel = 0,
				LayoutOrder = 1,
			}, {
				border = e("Frame", {
					Size = UDim2.new(1, 0, 0, 1),
					Position = UDim2.new(0, 0, 1, -1),
					BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
					BorderSizePixel = 0,
				}),
				title = e("TextLabel", {
					Text = "Help & Shortcuts",
					Size = UDim2.new(1, -40, 1, 0),
					Position = UDim2.fromOffset(10, 0),
					BackgroundTransparency = 1,
					TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
					TextSize = HEADING_TEXT_SIZE,
					Font = Enum.Font.SourceSans,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				close = e(ModalCloseButton, {
					onActivated = props.onClose,
				}),
			}),

			body = e(StudioComponents.ScrollFrame, {
				Size = UDim2.new(1, -2, 1, -35),
				ScrollingDirection = Enum.ScrollingDirection.Y,
				Layout = {
					ClassName = "UIListLayout",
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 4),
				},
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
				LayoutOrder = 2,
			}, {
				usageHeader = sectionHeader(theme, "Usage", 1),
				usageBody = guideText(theme, 2),
				spacerGuide = e("Frame", {
					Size = UDim2.new(1, 0, 0, SECTION_GAP),
					BackgroundTransparency = 1,
					LayoutOrder = 3,
				}),
				kbHeader = sectionHeader(theme, "Keyboard", 4),
				r1 = shortcutRow("Space", "Play or pause animation", 5),
				spacer1 = e("Frame", {
					Size = UDim2.new(1, 0, 0, SECTION_GAP),
					BackgroundTransparency = 1,
					LayoutOrder = 6,
				}),
				selHeader = sectionHeader(theme, "Selection", 7),
				r2 = shortcutRow("Ctrl + click", "Add or remove a model in multi-selection", 8),
				spacer2 = e("Frame", {
					Size = UDim2.new(1, 0, 0, SECTION_GAP),
					BackgroundTransparency = 1,
					LayoutOrder = 9,
				}),
				prevHeader = sectionHeader(theme, "Preview (mouse)", 10),
				r3 = shortcutRow("Shift + drag", "Pan the camera", 11),
				r4 = shortcutRow("Scroll wheel", "Zoom camera distance", 12),
				r5 = shortcutRow("Ctrl + scroll", "Adjust field of view", 13),
				spacerCredits = e("Frame", {
					Size = UDim2.new(1, 0, 0, SECTION_GAP),
					BackgroundTransparency = 1,
					LayoutOrder = 14,
				}),
				creditsHeader = sectionHeader(theme, "Credits", 15),
				creditsBody = e("TextLabel", {
					Text = "CahwarDev for inspiration",
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
					TextSize = CONTENT_TEXT_SIZE,
					Font = Enum.Font.SourceSans,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					LayoutOrder = 16,
				}),
			}),
		}),
	})
end

return HelpShortcutsModal

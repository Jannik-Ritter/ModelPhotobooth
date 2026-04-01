local Packages = script.Parent.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local Darkener = require(script.Parent.Darkener)
local ModalTitleBar = require(script.Parent.ModalTitleBar)
local constants = require(script.Parent.Parent.Parent.constants)

local e = React.createElement

type Props = {
	onClose: () -> (),
	initialTab: string?,
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

local function bodyText(theme, text: string, layoutOrder: number)
	return e("TextLabel", {
		Text = text,
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

local function spacer(layoutOrder: number)
	return e("Frame", {
		Size = UDim2.new(1, 0, 0, SECTION_GAP),
		BackgroundTransparency = 1,
		LayoutOrder = layoutOrder,
	})
end

local function HelpShortcutsModal(props: Props)
	local theme = StudioComponents.useTheme()
	local selectedTab, setSelectedTab = React.useState(props.initialTab or "General")

	local generalContent = e(StudioComponents.ScrollFrame, {
		Size = UDim2.fromScale(1, 1),
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
	}, {
		warning = e("TextLabel", {
			Text = "<font color='#FF7800'>Disclaimer: Uploading is currently restricted by Roblox. See Common Issues - 'Upload failed' for more information. Explorting is not affected.</font>",
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
			TextSize = CONTENT_TEXT_SIZE,
			Font = Enum.Font.SourceSans,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			LayoutOrder = 1,
			RichText = true,
		}),
		usageHeader = sectionHeader(theme, "Usage", 1),
		usageBody = e("TextLabel", {
			Text = "Select a model or part in the Explorer to add it to the Models strip.\n"
				.. "The right panel contains camera, effects, animation, and export settings. Save your favorites as presets.\n"
				.. "Click Preview to render, then Export to place the result in Workspace.\n"
				.. "Click any render in the Renders strip to view it before exporting.\n"
				.. 'To save as a PNG, export first, then right-click the result and choose "Save/Export" -> "Export as Obj".\n'
				.. "To render with animation, place a compatible Animation instance inside the model.",
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
			TextSize = CONTENT_TEXT_SIZE,
			Font = Enum.Font.SourceSans,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			LayoutOrder = 2,
			RichText = true,
		}),
		spacerGuide = spacer(3),
		kbHeader = sectionHeader(theme, "Keyboard", 4),
		r1 = shortcutRow("Space", "Play or pause animation", 5),
		spacer1 = spacer(6),
		selHeader = sectionHeader(theme, "Selection", 7),
		r2 = shortcutRow("Ctrl + click", "Add or remove a model in multi-selection", 8),
		spacer2 = spacer(9),
		prevHeader = sectionHeader(theme, "Preview (mouse)", 10),
		r3 = shortcutRow("Shift + drag", "Pan the camera", 11),
		r4 = shortcutRow("Scroll wheel", "Zoom camera distance", 12),
		r5 = shortcutRow("Ctrl + scroll", "Adjust field of view", 13),
		spacerCredits = spacer(14),
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
	})

	local issuesContent = e(StudioComponents.ScrollFrame, {
		Size = UDim2.fromScale(1, 1),
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
	}, {
		viewportHeader = sectionHeader(theme, "Viewport too small", 4),
		viewportBody = bodyText(
			theme,
			"Make the Roblox viewport (the space where you move your camera) in Studio as big as possible. "
				.. "It needs to be at least "
				.. tostring(constants.HELP_MIN_VIEWPORT_PX)
				.. "px tall and wide to support the highest settings. "
				.. "If that doesn't work, your monitor might be too small. In that case, change the resolution plugin-setting to be smaller."
				.. "Or alternatively, enable device emulation in Studio settings.",
			4
		),
		spacer1 = spacer(5),
		uploadHeader = sectionHeader(theme, "Upload failed", 6),
		uploadBody = bodyText(
			theme,
			"Uploading only works if you installed this plugin locally and enabled the CreateAssetAsync Lua API Beta in Studio settings. If you installed the plugin from the Creatore Store, you will unfotunately have to wait until Roblox releases this API endpoint.\nIn the mean time, exporting works just fine too, you just have to upload the PNG files to Roblox yourself. ",
			7
		),
		spacerContact = spacer(8),
		contactBody = e("TextLabel", {
			Text = "Didn't find your issue? Message me @Chahier",
			Size = UDim2.new(1, 0, 0, 18),
			BackgroundTransparency = 1,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.SubText),
			TextSize = CONTENT_TEXT_SIZE,
			Font = Enum.Font.SourceSans,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			LayoutOrder = 9,
		}),
	})

	-- Title 32 + tab container 285 (backdrop does not dismiss; only titlebar close)
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

			titleBar = e(ModalTitleBar, {
				title = "Help & Shortcuts",
				onClose = props.onClose,
				layoutOrder = 1,
				textSize = HEADING_TEXT_SIZE,
			}),

			tabContainer = e(StudioComponents.TabContainer, {
				Size = UDim2.new(1, -2, 1, -35),
				SelectedTab = selectedTab,
				OnTabSelected = setSelectedTab,
				LayoutOrder = 2,
			}, {
				["General"] = {
					LayoutOrder = 1,
					Content = generalContent,
				},
				["Common Issues"] = {
					LayoutOrder = 2,
					Content = issuesContent,
				},
			}),
		}),
	})
end

return HelpShortcutsModal

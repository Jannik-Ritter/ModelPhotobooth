local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local Store = require(script.Parent.Parent.Store)
local CollapsibleSection = require(script.Parent.effects.CollapsibleSection)
local EffectPreview = require(script.Parent.effects.EffectPreview)
local OutlineEffectRow = require(script.Parent.effects.OutlineEffectRow)
local ShadowEffectRow = require(script.Parent.effects.ShadowEffectRow)
local OuterGlowEffectRow = require(script.Parent.effects.OuterGlowEffectRow)
local ChromaticAberrationEffectRow = require(script.Parent.effects.ChromaticAberrationEffectRow)

local e = React.createElement

local PRESET_ORDER = { "Front", "Side", "Iso", "3/4" }
local EXPORT_SIZES = {
	{ label = "Native", value = 0 },
	{ label = "1024", value = 1024 },
	{ label = "512", value = 512 },
	{ label = "256", value = 256 },
	{ label = "128", value = 128 },
}
local BG_PRESETS = {
	{ label = "None", mode = "transparent", color = nil },
	{ label = "White", mode = "color", color = Color3.new(1, 1, 1) },
	{ label = "Black", mode = "color", color = Color3.fromRGB(18, 18, 18) },
}
local DROPDOWN_ROW_HEIGHT = 20
local DROPDOWN_LABEL_TEXT_SIZE = 16
local DROPDOWN_LABEL_WIDTHS = {
	Preset = 52,
	Color = 52,
	Resolution = 64,
}

type Props = {
	state: Store.AppState,
	dispatch: (any) -> (),
	onSavePreset: () -> (),
	onApplyPreset: (index: number) -> (),
	onRenamePreset: (index: number) -> (),
	onDeletePreset: (index: number) -> (),
}

local function Sidebar(props: Props)
	local state = props.state
	local A = Store.ACTIONS
	local theme = StudioComponents.useTheme()
	local selectedTab, setSelectedTab = React.useState("Settings")

	local function isCollapsed(section: string): boolean
		return state.collapsedSections[section] == true
	end

	local function toggleSection(section: string)
		return function()
			props.dispatch({ type = A.TOGGLE_SECTION, value = section })
		end
	end

	local function dropdownLabel(text: string, width: number)
		return e("TextLabel", {
			Text = text,
			Size = UDim2.new(0, width, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Font = Enum.Font.SourceSans,
			TextSize = DROPDOWN_LABEL_TEXT_SIZE,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			LayoutOrder = 1,
		})
	end

	-- Camera presets
	local activePreset = nil
	for name, p in pairs(Store.PRESETS) do
		if state.yaw == p.yaw and state.pitch == p.pitch and state.fov == p.fov then
			activePreset = name
			break
		end
	end

	-- Background selected label
	local selectedBg = nil
	for _, preset in ipairs(BG_PRESETS) do
		local match = (preset.mode == "transparent" and state.bgMode == "transparent")
			or (
				preset.mode == "color"
				and state.bgMode == "color"
				and preset.color ~= nil
				and state.bgColor == preset.color
			)
		if match then
			selectedBg = preset.label
			break
		end
	end

	-- Export size selected label
	local selectedSize = nil
	for _, opt in ipairs(EXPORT_SIZES) do
		if state.exportSize == opt.value then
			selectedSize = opt.label
			break
		end
	end

	-- Build preset rows
	local presetRows = {}
	for i, preset in ipairs(state.presets) do
		local idx = i
		presetRows["preset_" .. i] = e("Frame", {
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundTransparency = 1,
			LayoutOrder = i + 1,
		}, {
			layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			name = e(StudioComponents.Label, {
				Text = preset.name,
				Size = UDim2.new(1, -112, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				LayoutOrder = 1,
			}),
			apply = e(StudioComponents.MainButton, {
				Text = "Apply",
				OnActivated = function()
					props.onApplyPreset(idx)
				end,
				Size = UDim2.fromOffset(48, 22),
				LayoutOrder = 2,
			}),
			rename = e(StudioComponents.Button, {
				Text = "…",
				OnActivated = function()
					props.onRenamePreset(idx)
				end,
				Size = UDim2.fromOffset(26, 22),
				LayoutOrder = 3,
			}),
			delete = e(StudioComponents.Button, {
				Text = "×",
				OnActivated = function()
					props.onDeletePreset(idx)
				end,
				Size = UDim2.fromOffset(26, 22),
				LayoutOrder = 4,
			}),
		})
	end
	presetRows["layout"] = e("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
	})

	local settingsContent = e(StudioComponents.ScrollFrame, {
		Size = UDim2.fromScale(1, 1),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Layout = {
			ClassName = "UIListLayout",
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		},
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
	}, {
		-- Camera section
		camera = e(CollapsibleSection, {
			title = "Camera",
			collapsed = isCollapsed("Camera"),
			onToggle = toggleSection("Camera"),
			LayoutOrder = 1,
		}, {
			presets = e("Frame", {
				Size = UDim2.new(1, 0, 0, DROPDOWN_ROW_HEIGHT),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}, {
				layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6),
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
				label = dropdownLabel("Preset", DROPDOWN_LABEL_WIDTHS.Preset),
				dropdown = e(StudioComponents.Dropdown, {
					Items = PRESET_ORDER,
					SelectedItem = activePreset,
					OnItemSelected = function(name)
						if name then
							local preset = Store.PRESETS[name]
							props.dispatch({
								type = A.SET_CAMERA,
								yaw = preset.yaw,
								pitch = preset.pitch,
								fov = preset.fov,
							})
						end
					end,
					RowHeight = 22,
					Size = UDim2.new(1, -58, 1, 0),
					LayoutOrder = 2,
				}),
			}),
			fov = e("Frame", {
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, {
				layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6),
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
				label = e(StudioComponents.Label, {
					Text = "FOV",
					Size = UDim2.new(0, 30, 1, 0),
					LayoutOrder = 1,
				}),
				slider = e(StudioComponents.Slider, {
					Value = state.fov,
					OnChanged = function(v)
						props.dispatch({ type = A.SET_FOV, value = v })
					end,
					Min = 1,
					Max = 120,
					Step = 1,
					Size = UDim2.new(1, -68, 1, 0),
					LayoutOrder = 2,
				}),
				value = e(StudioComponents.Label, {
					Text = tostring(math.floor(state.fov)) .. "\u{00B0}",
					Size = UDim2.new(0, 26, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Right,
					LayoutOrder = 3,
				}),
			}),
			distance = e("Frame", {
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundTransparency = 1,
				LayoutOrder = 3,
			}, {
				layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6),
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
				label = e(StudioComponents.Label, {
					Text = "Dist",
					Size = UDim2.new(0, 30, 1, 0),
					LayoutOrder = 1,
				}),
				slider = e(StudioComponents.Slider, {
					Value = state.cameraDistance,
					OnChanged = function(v)
						props.dispatch({ type = A.SET_CAMERA_DISTANCE, value = v })
					end,
					Min = 0.5,
					Max = 3,
					Step = 0.05,
					Size = UDim2.new(1, -68, 1, 0),
					LayoutOrder = 2,
				}),
				value = e(StudioComponents.Label, {
					Text = string.format("%.2fx", state.cameraDistance),
					Size = UDim2.new(0, 26, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Right,
					LayoutOrder = 3,
				}),
			}),
		}),

		-- Background section
		background = e(CollapsibleSection, {
			title = "Background",
			collapsed = isCollapsed("Background"),
			onToggle = toggleSection("Background"),
			LayoutOrder = 2,
		}, {
			color = e("Frame", {
				Size = UDim2.new(1, 0, 0, DROPDOWN_ROW_HEIGHT),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}, {
				layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6),
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
				label = dropdownLabel("Color", DROPDOWN_LABEL_WIDTHS.Color),
				dropdown = e(StudioComponents.Dropdown, {
					Items = { "None", "White", "Black" },
					SelectedItem = selectedBg,
					OnItemSelected = function(lbl)
						if lbl then
							for _, preset in ipairs(BG_PRESETS) do
								if preset.label == lbl then
									props.dispatch({ type = A.SET_BG_MODE, value = preset.mode })
									if preset.color then
										props.dispatch({ type = A.SET_BG_COLOR, value = preset.color })
									end
									break
								end
							end
						end
					end,
					RowHeight = 22,
					Size = UDim2.new(1, -58, 1, 0),
					LayoutOrder = 2,
				}),
			}),
		}),

		-- Effects Preview section
		effectsPreview = e(CollapsibleSection, {
			title = "Effects Preview",
			collapsed = isCollapsed("EffectsPreview"),
			onToggle = toggleSection("EffectsPreview"),
			LayoutOrder = 3,
		}, {
			preview = e(EffectPreview, {
				outline = state.outline,
				dropShadow = state.dropShadow,
				innerShadow = state.innerShadow,
				outerGlow = state.outerGlow,
				chromaticAberration = state.chromaticAberration,
				bgMode = state.bgMode,
				bgColor = state.bgColor,
				LayoutOrder = 1,
			}),
		}),

		-- Outline section
		outline = e(CollapsibleSection, {
			title = "Outline",
			collapsed = isCollapsed("Outline"),
			onToggle = toggleSection("Outline"),
			LayoutOrder = 4,
		}, {
			row = e(OutlineEffectRow, {
				enabled = state.outline.enabled,
				color = state.outline.color,
				thickness = state.outline.thickness,
				onToggle = function(v)
					props.dispatch({ type = A.SET_OUTLINE, value = { enabled = v } })
				end,
				onColorChanged = function(c)
					props.dispatch({ type = A.SET_OUTLINE, value = { color = c } })
				end,
				onThicknessChanged = function(v)
					props.dispatch({ type = A.SET_OUTLINE, value = { thickness = v } })
				end,
				onColorPickerToggle = function()
					local target = if state.colorPickerTarget == "outline" then nil else "outline"
					props.dispatch({ type = A.SET_COLOR_PICKER_TARGET, value = target })
				end,
				LayoutOrder = 1,
			}),
		}),

		-- Drop Shadow section
		dropShadow = e(CollapsibleSection, {
			title = "Drop Shadow",
			collapsed = isCollapsed("DropShadow"),
			onToggle = toggleSection("DropShadow"),
			LayoutOrder = 5,
		}, {
			row = e(ShadowEffectRow, {
				label = "Shadow",
				enabled = state.dropShadow.enabled,
				color = state.dropShadow.color,
				opacity = state.dropShadow.opacity,
				distance = state.dropShadow.distance,
				blur = state.dropShadow.blur,
				angle = state.dropShadow.angle,
				onToggle = function(v)
					props.dispatch({ type = A.SET_DROP_SHADOW, value = { enabled = v } })
				end,
				onColorChanged = function(c)
					props.dispatch({ type = A.SET_DROP_SHADOW, value = { color = c } })
				end,
				onOpacityChanged = function(v)
					props.dispatch({ type = A.SET_DROP_SHADOW, value = { opacity = v } })
				end,
				onDistanceChanged = function(v)
					props.dispatch({ type = A.SET_DROP_SHADOW, value = { distance = v } })
				end,
				onBlurChanged = function(v)
					props.dispatch({ type = A.SET_DROP_SHADOW, value = { blur = v } })
				end,
				onAngleChanged = function(v)
					props.dispatch({ type = A.SET_DROP_SHADOW, value = { angle = v } })
				end,
				onColorPickerToggle = function()
					local target = if state.colorPickerTarget == "shadow" then nil else "shadow"
					props.dispatch({ type = A.SET_COLOR_PICKER_TARGET, value = target })
				end,
				LayoutOrder = 1,
			}),
		}),

		-- Inner Shadow section
		innerShadow = e(CollapsibleSection, {
			title = "Inner Shadow",
			collapsed = isCollapsed("InnerShadow"),
			onToggle = toggleSection("InnerShadow"),
			LayoutOrder = 6,
		}, {
			row = e(ShadowEffectRow, {
				label = "Inner",
				enabled = state.innerShadow.enabled,
				color = state.innerShadow.color,
				opacity = state.innerShadow.opacity,
				distance = state.innerShadow.distance,
				blur = state.innerShadow.blur,
				angle = state.innerShadow.angle,
				onToggle = function(v)
					props.dispatch({ type = A.SET_INNER_SHADOW, value = { enabled = v } })
				end,
				onColorChanged = function(c)
					props.dispatch({ type = A.SET_INNER_SHADOW, value = { color = c } })
				end,
				onOpacityChanged = function(v)
					props.dispatch({ type = A.SET_INNER_SHADOW, value = { opacity = v } })
				end,
				onDistanceChanged = function(v)
					props.dispatch({ type = A.SET_INNER_SHADOW, value = { distance = v } })
				end,
				onBlurChanged = function(v)
					props.dispatch({ type = A.SET_INNER_SHADOW, value = { blur = v } })
				end,
				onAngleChanged = function(v)
					props.dispatch({ type = A.SET_INNER_SHADOW, value = { angle = v } })
				end,
				onColorPickerToggle = function()
					local target = if state.colorPickerTarget == "inner" then nil else "inner"
					props.dispatch({ type = A.SET_COLOR_PICKER_TARGET, value = target })
				end,
				LayoutOrder = 1,
			}),
		}),

		-- Outer Glow section
		outerGlow = e(CollapsibleSection, {
			title = "Outer Glow",
			collapsed = isCollapsed("OuterGlow"),
			onToggle = toggleSection("OuterGlow"),
			LayoutOrder = 7,
		}, {
			row = e(OuterGlowEffectRow, {
				enabled = state.outerGlow.enabled,
				color = state.outerGlow.color,
				size = state.outerGlow.size,
				opacity = state.outerGlow.opacity,
				blur = state.outerGlow.blur,
				onToggle = function(v)
					props.dispatch({ type = A.SET_OUTER_GLOW, value = { enabled = v } })
				end,
				onColorChanged = function(c)
					props.dispatch({ type = A.SET_OUTER_GLOW, value = { color = c } })
				end,
				onSizeChanged = function(v)
					props.dispatch({ type = A.SET_OUTER_GLOW, value = { size = v } })
				end,
				onOpacityChanged = function(v)
					props.dispatch({ type = A.SET_OUTER_GLOW, value = { opacity = v } })
				end,
				onBlurChanged = function(v)
					props.dispatch({ type = A.SET_OUTER_GLOW, value = { blur = v } })
				end,
				onColorPickerToggle = function()
					local target = if state.colorPickerTarget == "glow" then nil else "glow"
					props.dispatch({ type = A.SET_COLOR_PICKER_TARGET, value = target })
				end,
				LayoutOrder = 1,
			}),
		}),

		-- Chromatic Aberration section
		chromaticAberration = e(CollapsibleSection, {
			title = "Chromatic Aberration",
			collapsed = isCollapsed("ChromaticAberration"),
			onToggle = toggleSection("ChromaticAberration"),
			LayoutOrder = 8,
		}, {
			row = e(ChromaticAberrationEffectRow, {
				enabled = state.chromaticAberration.enabled,
				amount = state.chromaticAberration.amount,
				onToggle = function(v)
					props.dispatch({ type = A.SET_CHROMATIC_ABERRATION, value = { enabled = v } })
				end,
				onAmountChanged = function(v)
					props.dispatch({ type = A.SET_CHROMATIC_ABERRATION, value = { amount = v } })
				end,
				LayoutOrder = 1,
			}),
		}),

		-- Export section
		export = e(CollapsibleSection, {
			title = "Export",
			collapsed = isCollapsed("Export"),
			onToggle = toggleSection("Export"),
			LayoutOrder = 9,
		}, {
			size = e("Frame", {
				Size = UDim2.new(1, 0, 0, DROPDOWN_ROW_HEIGHT),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}, {
				layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6),
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
				label = dropdownLabel("Resolution", DROPDOWN_LABEL_WIDTHS.Resolution),
				dropdown = e(StudioComponents.Dropdown, {
					Items = { "Native", "1024", "512", "256", "128" },
					SelectedItem = selectedSize,
					OnItemSelected = function(lbl)
						if lbl then
							for _, opt in ipairs(EXPORT_SIZES) do
								if opt.label == lbl then
									props.dispatch({ type = A.SET_EXPORT_SIZE, value = opt.value })
									break
								end
							end
						end
					end,
					RowHeight = 22,
					Size = UDim2.new(1, -70, 1, 0),
					LayoutOrder = 2,
				}),
			}),
		}),
	})

	local presetsContent = e(StudioComponents.ScrollFrame, {
		Size = UDim2.fromScale(1, 1),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Layout = {
			ClassName = "UIListLayout",
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		},
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
	}, {
		saveButton = e(StudioComponents.MainButton, {
			Text = "Save Current",
			OnActivated = props.onSavePreset,
			Size = UDim2.new(1, 0, 0, 24),
			LayoutOrder = 1,
		}),
		spacer = e("Frame", {
			Size = UDim2.new(1, 0, 0, 8),
			BackgroundTransparency = 1,
			LayoutOrder = 2,
		}),
		rows = e("Frame", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 3,
		}, presetRows),
	})

	return e("Frame", {
		Size = UDim2.new(0, 220, 1, 0),
		Position = UDim2.new(1, -220, 0, 0),
		BackgroundTransparency = 1,
	}, {
		border = e("Frame", {
			Size = UDim2.new(0, 1, 1, 0),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
			BorderSizePixel = 0,
			ZIndex = 2,
		}),
		tabs = e(StudioComponents.TabContainer, {
			Size = UDim2.new(1, -1, 1, 0),
			Position = UDim2.fromOffset(1, 0),
			SelectedTab = selectedTab,
			OnTabSelected = setSelectedTab,
		}, {
			["Settings"] = {
				LayoutOrder = 1,
				Content = settingsContent,
			},
			["Presets"] = {
				LayoutOrder = 2,
				Content = presetsContent,
			},
		}),
	})
end

return Sidebar

local Lighting = game:GetService("Lighting")

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
local SliderRow = require(script.Parent.effects.SliderRow)
local limitDecimals = require(script.Parent.Parent.utils.limitDecimals)
local constants = require(script.Parent.Parent.constants)

local e = React.createElement

local PRESET_ORDER = { "Front", "Side", "Back", "Top", "Iso", "Angled" }
local EXPORT_DROPDOWN_LABELS: { string } = {}
for _, opt in ipairs(constants.EXPORT_SIZE_PRESETS) do
	table.insert(EXPORT_DROPDOWN_LABELS, opt.label)
end
local BG_PRESETS = {
	{ label = "None", mode = "transparent", color = nil },
	{ label = "White", mode = "color", color = Color3.new(1, 1, 1) },
	{ label = "Black", mode = "color", color = Color3.fromRGB(18, 18, 18) },
	{ label = "Custom", mode = "custom", color = nil },
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

	local formatCameraOffset = function(value: number): string
		return limitDecimals(value, 3)
	end

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
		if state.yaw == p.yaw and state.pitch == p.pitch and state.fov == p.fov and state.roll == 0 then
			activePreset = name
			break
		end
	end

	-- Background selected label
	local selectedBg = nil
	for _, preset in ipairs(BG_PRESETS) do
		local match = (preset.mode == "transparent" and state.bgMode == "transparent")
			or (preset.mode == "custom" and state.bgMode == "custom")
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
	for _, opt in ipairs(constants.EXPORT_SIZE_PRESETS) do
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
		-- Export section
		export = e(CollapsibleSection, {
			title = "Export",
			collapsed = isCollapsed("Export"),
			onToggle = toggleSection("Export"),
			LayoutOrder = 0,
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
					Items = EXPORT_DROPDOWN_LABELS,
					SelectedItem = selectedSize,
					OnItemSelected = function(lbl)
						if lbl then
							for _, opt in ipairs(constants.EXPORT_SIZE_PRESETS) do
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
								roll = 0,
								resetOffset = true,
							})
						end
					end,
					RowHeight = 22,
					Size = UDim2.new(1, -58, 1, 0),
					LayoutOrder = 2,
				}),
			}),
			fov = e(SliderRow, {
				label = "FOV",
				value = state.fov,
				min = constants.FOV_MIN,
				max = constants.FOV_MAX,
				onChanged = function(v)
					props.dispatch({ type = A.SET_FOV, value = v })
				end,
				layoutOrder = 2,
				suffix = "\u{00B0}",
				labelWidth = 30,
				valueWidth = 26,
			}),
			distance = e(SliderRow, {
				label = "Dist",
				value = state.cameraDistance,
				min = constants.CAMERA_DISTANCE_MIN,
				max = constants.CAMERA_DISTANCE_MAX,
				step = 0.01,
				decimals = 2,
				onChanged = function(v)
					props.dispatch({ type = A.SET_CAMERA_DISTANCE, value = v })
				end,
				layoutOrder = 3,
				suffix = "x",
				labelWidth = 30,
				valueWidth = 26,
			}),
			roll = e(SliderRow, {
				label = "Roll",
				value = state.roll,
				min = -180,
				max = 180,
				onChanged = function(v)
					props.dispatch({ type = A.SET_ROLL, value = v })
				end,
				layoutOrder = 4,
				suffix = "\u{00B0}",
				labelWidth = 30,
				valueWidth = 26,
			}),
			offset = e("Frame", {
				Size = UDim2.new(1, 0, 0, 44),
				BackgroundTransparency = 1,
				LayoutOrder = 5,
			}, {
				outerLayout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 2),
				}),
				header = e(StudioComponents.Label, {
					Text = "Offset",
					Size = UDim2.new(1, 0, 0, 18),
					LayoutOrder = 1,
				}),
				inputs = e("Frame", {
					Size = UDim2.new(1, 0, 0, 22),
					BackgroundTransparency = 1,
					LayoutOrder = 2,
				}, {
					layout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 4),
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),
					labelX = e(StudioComponents.Label, {
						Text = "X",
						Size = UDim2.new(0, 10, 1, 0),
						TextXAlignment = Enum.TextXAlignment.Center,
						LayoutOrder = 1,
					}),
					axisX = e(StudioComponents.NumericInput, {
						Value = state.cameraOffsetX,
						FormatValue = formatCameraOffset,
						ClearTextOnFocus = false,
						OnValidChanged = function(v)
							props.dispatch({
								type = A.SET_CAMERA_OFFSET,
								x = v,
								y = state.cameraOffsetY,
								z = state.cameraOffsetZ,
							})
						end,
						Min = constants.CAMERA_OFFSET_MIN,
						Max = constants.CAMERA_OFFSET_MAX,
						Step = constants.CAMERA_OFFSET_STEP,
						Arrows = false,
						Size = UDim2.new(1 / 3, -18, 1, 0),
						LayoutOrder = 2,
					}),
					labelY = e(StudioComponents.Label, {
						Text = "Y",
						Size = UDim2.new(0, 10, 1, 0),
						TextXAlignment = Enum.TextXAlignment.Center,
						LayoutOrder = 3,
					}),
					axisY = e(StudioComponents.NumericInput, {
						Value = state.cameraOffsetY,
						FormatValue = formatCameraOffset,
						ClearTextOnFocus = false,
						OnValidChanged = function(v)
							props.dispatch({
								type = A.SET_CAMERA_OFFSET,
								x = state.cameraOffsetX,
								y = v,
								z = state.cameraOffsetZ,
							})
						end,
						Min = constants.CAMERA_OFFSET_MIN,
						Max = constants.CAMERA_OFFSET_MAX,
						Step = constants.CAMERA_OFFSET_STEP,
						Arrows = false,
						Size = UDim2.new(1 / 3, -18, 1, 0),
						LayoutOrder = 4,
					}),
					labelZ = e(StudioComponents.Label, {
						Text = "Z",
						Size = UDim2.new(0, 10, 1, 0),
						TextXAlignment = Enum.TextXAlignment.Center,
						LayoutOrder = 5,
					}),
					axisZ = e(StudioComponents.NumericInput, {
						Value = state.cameraOffsetZ,
						FormatValue = formatCameraOffset,
						ClearTextOnFocus = false,
						OnValidChanged = function(v)
							props.dispatch({
								type = A.SET_CAMERA_OFFSET,
								x = state.cameraOffsetX,
								y = state.cameraOffsetY,
								z = v,
							})
						end,
						Min = constants.CAMERA_OFFSET_MIN,
						Max = constants.CAMERA_OFFSET_MAX,
						Step = constants.CAMERA_OFFSET_STEP,
						Arrows = false,
						Size = UDim2.new(1 / 3, -18, 1, 0),
						LayoutOrder = 6,
					}),
				}),
			}),
		}),

		-- Lighting section
		lighting = e(CollapsibleSection, {
			title = "Lighting",
			collapsed = isCollapsed("Lighting"),
			onToggle = toggleSection("Lighting"),
			LayoutOrder = 2,
		}, {
			listLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
			}),
			lightColorRow = e("Frame", {
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}, {
				layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6),
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
				label = e(StudioComponents.Label, {
					Text = "Light Color",
					Size = UDim2.new(1, -22, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 1,
				}),
				swatch = e("TextButton", {
					Size = UDim2.fromOffset(16, 16),
					BackgroundColor3 = state.lighting.lightColor,
					BorderSizePixel = 0,
					Text = "",
					AutoButtonColor = false,
					LayoutOrder = 2,
					[React.Event.MouseButton1Click] = function()
						local target = if state.colorPickerTarget == "lightColor" then nil else "lightColor"
						props.dispatch({ type = A.SET_COLOR_PICKER_TARGET, value = target })
					end,
				}, {
					corner = e("UICorner", { CornerRadius = UDim.new(0, 3) }),
					stroke = e("UIStroke", {
						Color = theme:GetColor(Enum.StudioStyleGuideColor.Border),
						Thickness = 1,
					}),
				}),
			}),
			ambientRow = e("Frame", {
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
					Text = "Ambient",
					Size = UDim2.new(1, -22, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 1,
				}),
				swatch = e("TextButton", {
					Size = UDim2.fromOffset(16, 16),
					BackgroundColor3 = state.lighting.ambient,
					BorderSizePixel = 0,
					Text = "",
					AutoButtonColor = false,
					LayoutOrder = 2,
					[React.Event.MouseButton1Click] = function()
						local target = if state.colorPickerTarget == "ambient" then nil else "ambient"
						props.dispatch({ type = A.SET_COLOR_PICKER_TARGET, value = target })
					end,
				}, {
					corner = e("UICorner", { CornerRadius = UDim.new(0, 3) }),
					stroke = e("UIStroke", {
						Color = theme:GetColor(Enum.StudioStyleGuideColor.Border),
						Thickness = 1,
					}),
				}),
			}),
			directionRow = e("Frame", {
				Size = UDim2.new(1, 0, 0, 44),
				BackgroundTransparency = 1,
				LayoutOrder = 3,
			}, {
				outerLayout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 2),
				}),
				header = e(StudioComponents.Label, {
					Text = "Direction",
					Size = UDim2.new(1, 0, 0, 18),
					LayoutOrder = 1,
				}),
				inputs = e("Frame", {
					Size = UDim2.new(1, 0, 0, 22),
					BackgroundTransparency = 1,
					LayoutOrder = 2,
				}, {
					layout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 4),
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),
					labelX = e(StudioComponents.Label, {
						Text = "X",
						Size = UDim2.new(0, 10, 1, 0),
						TextXAlignment = Enum.TextXAlignment.Center,
						LayoutOrder = 1,
					}),
					axisX = e(StudioComponents.NumericInput, {
						Value = state.lighting.lightDirectionX,
						ClearTextOnFocus = false,
						OnValidChanged = function(v)
							props.dispatch({
								type = A.SET_LIGHTING,
								value = {
									lightDirectionX = v,
									lightDirectionY = state.lighting.lightDirectionY,
									lightDirectionZ = state.lighting.lightDirectionZ,
								},
							})
						end,
						Min = constants.LIGHT_DIRECTION_MIN,
						Max = constants.LIGHT_DIRECTION_MAX,
						Step = constants.LIGHT_DIRECTION_STEP,
						Arrows = false,
						Size = UDim2.new(1 / 3, -18, 1, 0),
						LayoutOrder = 2,
					}),
					labelY = e(StudioComponents.Label, {
						Text = "Y",
						Size = UDim2.new(0, 10, 1, 0),
						TextXAlignment = Enum.TextXAlignment.Center,
						LayoutOrder = 3,
					}),
					axisY = e(StudioComponents.NumericInput, {
						Value = state.lighting.lightDirectionY,
						ClearTextOnFocus = false,
						OnValidChanged = function(v)
							props.dispatch({
								type = A.SET_LIGHTING,
								value = {
									lightDirectionX = state.lighting.lightDirectionX,
									lightDirectionY = v,
									lightDirectionZ = state.lighting.lightDirectionZ,
								},
							})
						end,
						Min = constants.LIGHT_DIRECTION_MIN,
						Max = constants.LIGHT_DIRECTION_MAX,
						Step = constants.LIGHT_DIRECTION_STEP,
						Arrows = false,
						Size = UDim2.new(1 / 3, -18, 1, 0),
						LayoutOrder = 4,
					}),
					labelZ = e(StudioComponents.Label, {
						Text = "Z",
						Size = UDim2.new(0, 10, 1, 0),
						TextXAlignment = Enum.TextXAlignment.Center,
						LayoutOrder = 5,
					}),
					axisZ = e(StudioComponents.NumericInput, {
						Value = state.lighting.lightDirectionZ,
						ClearTextOnFocus = false,
						OnValidChanged = function(v)
							props.dispatch({
								type = A.SET_LIGHTING,
								value = {
									lightDirectionX = state.lighting.lightDirectionX,
									lightDirectionY = state.lighting.lightDirectionY,
									lightDirectionZ = v,
								},
							})
						end,
						Min = constants.LIGHT_DIRECTION_MIN,
						Max = constants.LIGHT_DIRECTION_MAX,
						Step = constants.LIGHT_DIRECTION_STEP,
						Arrows = false,
						Size = UDim2.new(1 / 3, -18, 1, 0),
						LayoutOrder = 6,
					}),
				}),
			}),
			syncButton = e(StudioComponents.Button, {
				Text = "Sync Lighting",
				Size = UDim2.new(1, 0, 0, 24),
				LayoutOrder = 4,
				OnActivated = function()
					props.dispatch({ type = A.SET_LIGHTING, value = {
						ambient = Lighting.Ambient,
					} })
				end,
			}),
		}),

		-- Background section
		background = e(CollapsibleSection, {
			title = "Background",
			collapsed = isCollapsed("Background"),
			onToggle = toggleSection("Background"),
			LayoutOrder = 3,
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
					Items = { "None", "White", "Black", "Custom" },
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
			customBg = if state.bgMode == "custom"
				then e("Frame", {
					Size = UDim2.new(1, 0, 0, DROPDOWN_ROW_HEIGHT),
					BackgroundTransparency = 1,
					LayoutOrder = 2,
				}, {
					layout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 6),
						VerticalAlignment = Enum.VerticalAlignment.Center,
						HorizontalFlex = Enum.UIFlexAlignment.Fill,
					}),
					label = dropdownLabel("Pick", DROPDOWN_LABEL_WIDTHS.Color),
					swatch = e("TextButton", {
						Size = UDim2.new(1, -58, 0, 16),
						BackgroundColor3 = state.bgColor,
						BorderSizePixel = 0,
						Text = "",
						AutoButtonColor = false,
						LayoutOrder = 2,
						[React.Event.MouseButton1Click] = function()
							local target = if state.colorPickerTarget == "background" then nil else "background"
							props.dispatch({ type = A.SET_COLOR_PICKER_TARGET, value = target })
						end,
					}, {
						aspectRatioConstraint = e("UIAspectRatioConstraint", { AspectRatio = 1 }),
						corner = e("UICorner", { CornerRadius = UDim.new(0, 3) }),
						stroke = e("UIStroke", {
							Color = theme:GetColor(Enum.StudioStyleGuideColor.Border),
							Thickness = 1,
						}),
					}),
				})
				else nil,
		}),

		-- Effects Preview section
		effectsPreview = e(CollapsibleSection, {
			title = "Effects Preview",
			collapsed = isCollapsed("EffectsPreview"),
			onToggle = toggleSection("EffectsPreview"),
			LayoutOrder = 4,
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
			LayoutOrder = 5,
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
			LayoutOrder = 6,
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
			LayoutOrder = 7,
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
			LayoutOrder = 8,
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
			LayoutOrder = 9,
		}, {
			row = e(ChromaticAberrationEffectRow, {
				enabled = state.chromaticAberration.enabled,
				distance = state.chromaticAberration.distance,
				opacity = state.chromaticAberration.opacity,
				angle = state.chromaticAberration.angle,
				onToggle = function(v)
					props.dispatch({ type = A.SET_CHROMATIC_ABERRATION, value = { enabled = v } })
				end,
				onDistanceChanged = function(v)
					props.dispatch({ type = A.SET_CHROMATIC_ABERRATION, value = { distance = v } })
				end,
				onOpacityChanged = function(v)
					props.dispatch({ type = A.SET_CHROMATIC_ABERRATION, value = { opacity = v } })
				end,
				onAngleChanged = function(v)
					props.dispatch({ type = A.SET_CHROMATIC_ABERRATION, value = { angle = v } })
				end,
				LayoutOrder = 1,
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
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
	}, {
		tabs = e(StudioComponents.TabContainer, {
			Size = UDim2.fromScale(1, 1),
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

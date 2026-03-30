local Packages = script.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local Selection = game:GetService("Selection")
local CollectionService = game:GetService("CollectionService")

local Store = require(script.Parent.Store)
local renderOne = require(script.Parent.lib.renderOne)
local exportAll = require(script.Parent.lib.exportAll)
local PresetSerialization = require(script.Parent.lib.presetSerialization)
local ToolbarStrip = require(script.Parent.components.ToolbarStrip)
local PreviewViewport = require(script.Parent.components.PreviewViewport)
local ModelStrip = require(script.Parent.components.ModelStrip)
local Sidebar = require(script.Parent.components.Sidebar)
local ImagePreviewModal = require(script.Parent.components.modals.ImagePreviewModal)
local ColorPickerModal = require(script.Parent.components.modals.ColorPickerModal)
local NameInputModal = require(script.Parent.components.modals.NameInputModal)
local ConfirmModal = require(script.Parent.components.modals.ConfirmModal)
local HelpShortcutsModal = require(script.Parent.components.modals.HelpShortcutsModal)
local Darkener = require(script.Parent.components.modals.Darkener)

local e = React.createElement
local MPB_TAG = "_MPBIcon"

type Props = {
	plugin: any,
}

local function App(props: Props)
	local state, dispatch = React.useReducer(Store.reducer, Store.DEFAULT_STATE)
	local renderingRef = React.useRef(false)
	local modelsRef = React.useRef(Store.DEFAULT_STATE.models)
	local activeInputsRef = React.useRef({} :: { [Enum.KeyCode]: boolean })
	local animationPlayingRef = React.useRef(false)
	local activeAnimationIndexRef = React.useRef(nil :: number?)
	local deleteConfirmIndex, setDeleteConfirmIndex = React.useState(nil :: number?)
	local helpOpen, setHelpOpen = React.useState(false)
	local sidebarAlpha, setSidebarAlpha = React.useState(0.65)
	local modelStripAlpha, setModelStripAlpha = React.useState(0.82)
	-- Drives PreviewViewport cursor; ref-based isShiftDown() does not re-render children on key repeat
	local shiftDown, setShiftDown = React.useState(false)

	-- Keep modelsRef current so the selection listener can access latest renders
	React.useEffect(function()
		modelsRef.current = state.models
	end)

	-- Keep animation refs current for input callbacks
	React.useEffect(function()
		animationPlayingRef.current = state.animationPlaying
	end)
	React.useEffect(function()
		activeAnimationIndexRef.current = state.activeAnimationIndex
	end)

	-- Selection listener
	React.useEffect(function()
		local function refresh()
			-- Build a lookup of existing entries by instance to preserve renders
			local existing: { [Instance]: Store.ModelEntry } = {}
			for _, entry in ipairs(modelsRef.current) do
				existing[entry.instance] = entry
			end

			local sel = Selection:Get()
			local models: { Store.ModelEntry } = {}
			for _, obj in ipairs(sel) do
				if CollectionService:HasTag(obj, MPB_TAG) then
					table.insert(models, {
						instance = obj,
						status = "ok" :: Store.RenderStatus,
						image = nil,
						isExported = true,
					})
				elseif obj:IsA("Model") or obj:IsA("BasePart") then
					local prev = existing[obj]
					table.insert(models, {
						instance = obj,
						status = if prev then prev.status else "idle" :: Store.RenderStatus,
						image = if prev then prev.image else nil,
						isExported = false,
					})
				end
			end
			dispatch({ type = Store.ACTIONS.SET_MODELS, value = models })
			dispatch({
				type = Store.ACTIONS.SET_SELECTION,
				value = if #models > 0 then { 1 } else {},
			})
		end
		local conn = Selection.SelectionChanged:Connect(refresh)
		refresh()
		return function()
			conn:Disconnect()
		end
	end, {} :: { any })

	-- Load persisted presets on mount
	React.useEffect(function()
		local raw = props.plugin:GetSetting("presets")
		if type(raw) == "table" then
			local ok, result = pcall(PresetSerialization.deserialize, raw)
			if ok then
				dispatch({ type = Store.ACTIONS.SET_PRESETS, value = result })
			end
		end
	end, {} :: { any })

	-- Persist presets whenever they change
	React.useEffect(function()
		props.plugin:SetSetting("presets", PresetSerialization.serialize(state.presets))
	end, { state.presets } :: { any })

	-- Active model entry (used for animation detection — defined early)
	local focusedIndex = state.selectedModelIndices[#state.selectedModelIndices]
	local activeEntry = if focusedIndex then state.models[focusedIndex] else nil
	local activeInstance = if activeEntry then activeEntry.instance else nil

	-- Detect animations in the active model
	React.useEffect(function()
		if not activeInstance then
			dispatch({ type = Store.ACTIONS.SET_ANIMATIONS, value = {} })
			return
		end
		local anims: { Store.AnimationInfo } = {}
		for _, desc in ipairs(activeInstance:GetDescendants()) do
			if desc:IsA("Animation") and desc.AnimationId ~= "" then
				table.insert(anims, {
					name = desc.Name,
					animationId = desc.AnimationId,
				})
			end
		end
		dispatch({ type = Store.ACTIONS.SET_ANIMATIONS, value = anims })
	end, { activeInstance } :: { any })

	local function renderSettings()
		return {
			yaw = state.yaw,
			pitch = state.pitch,
			roll = state.roll,
			fov = state.fov,
			cameraDistance = state.cameraDistance,
			cameraOffsetX = state.cameraOffsetX,
			cameraOffsetY = state.cameraOffsetY,
			cameraOffsetZ = state.cameraOffsetZ,
			outline = state.outline,
			dropShadow = state.dropShadow,
			innerShadow = state.innerShadow,
			outerGlow = state.outerGlow,
			chromaticAberration = state.chromaticAberration,
			bgMode = state.bgMode,
			bgColor = state.bgColor,
			exportSize = state.exportSize,
			animationId = if state.activeAnimationIndex
				then state.animations[state.activeAnimationIndex]
					and state.animations[state.activeAnimationIndex].animationId
				else nil,
			animationTimePosition = state.animationTimePosition,
		}
	end

	local function onWidgetInputBegan(_, input)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			activeInputsRef.current[input.KeyCode] = true
			if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
				setShiftDown(
					activeInputsRef.current[Enum.KeyCode.LeftShift] == true
						or activeInputsRef.current[Enum.KeyCode.RightShift] == true
				)
			end
			if input.KeyCode == Enum.KeyCode.Space and activeAnimationIndexRef.current then
				dispatch({
					type = Store.ACTIONS.SET_ANIMATION_PLAYING,
					value = not animationPlayingRef.current,
				})
			end
		end
	end

	local function onWidgetInputEnded(_, input)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			activeInputsRef.current[input.KeyCode] = nil
			if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
				setShiftDown(
					activeInputsRef.current[Enum.KeyCode.LeftShift] == true
						or activeInputsRef.current[Enum.KeyCode.RightShift] == true
				)
			end
		end
	end

	local function isKeyDown(key: Enum.KeyCode)
		return activeInputsRef.current[key]
	end

	local function isCtrlDown()
		return isKeyDown(Enum.KeyCode.LeftControl) or isKeyDown(Enum.KeyCode.RightControl)
	end

	local function isShiftDown()
		return isKeyDown(Enum.KeyCode.LeftShift) or isKeyDown(Enum.KeyCode.RightShift)
	end

	-- Animation callbacks
	local function onSelectAnimation(index: number?)
		dispatch({ type = Store.ACTIONS.SET_ACTIVE_ANIMATION, value = index })
	end

	local function onSetAnimationPlaying(playing: boolean)
		dispatch({ type = Store.ACTIONS.SET_ANIMATION_PLAYING, value = playing })
	end

	local function onSetAnimationTimePosition(time: number)
		dispatch({ type = Store.ACTIONS.SET_ANIMATION_TIME, value = time })
	end

	local function onSetAnimationLength(length: number)
		dispatch({ type = Store.ACTIONS.SET_ANIMATION_LENGTH, value = length })
	end

	-- Render the currently selected models
	local function startRenderSelected()
		if renderingRef.current then
			return
		end
		local targets = {}
		for _, idx in ipairs(state.selectedModelIndices) do
			local entry = state.models[idx]
			if entry and not entry.isExported then
				table.insert(targets, { index = idx, entry = entry })
			end
		end
		if #targets == 0 then
			return
		end
		-- Pause animation playback during render
		if animationPlayingRef.current then
			dispatch({ type = Store.ACTIONS.SET_ANIMATION_PLAYING, value = false })
		end
		renderingRef.current = true
		dispatch({ type = Store.ACTIONS.SET_RENDERING, rendering = true, progress = 0, total = #targets })

		task.spawn(function()
			for i, target in ipairs(targets) do
				dispatch({ type = Store.ACTIONS.SET_RENDER_STATUS, index = target.index, status = "pending" })
				dispatch({ type = Store.ACTIONS.SET_RENDERING, rendering = true, progress = i - 1, total = #targets })

				local ok, img = renderOne(target.entry.instance, renderSettings()):await()
				dispatch({
					type = Store.ACTIONS.SET_RENDER_STATUS,
					index = target.index,
					status = if ok then "ok" else "fail",
					image = if ok then img else nil,
				})
				dispatch({ type = Store.ACTIONS.SET_RENDERING, rendering = true, progress = i, total = #targets })
				task.wait()
			end
			dispatch({ type = Store.ACTIONS.SET_RENDERING, rendering = false, progress = 0, total = 0 })
			renderingRef.current = false
		end)
	end

	-- Render all non-exported models
	local function startRenderAll()
		if renderingRef.current then
			return
		end
		local targets = {}
		for i, entry in ipairs(state.models) do
			if not entry.isExported then
				table.insert(targets, { index = i, entry = entry })
			end
		end
		if #targets == 0 then
			return
		end
		-- Pause animation playback during render
		if animationPlayingRef.current then
			dispatch({ type = Store.ACTIONS.SET_ANIMATION_PLAYING, value = false })
		end
		renderingRef.current = true
		dispatch({ type = Store.ACTIONS.SET_RENDERING, rendering = true, progress = 0, total = #targets })

		task.spawn(function()
			for i, target in ipairs(targets) do
				dispatch({ type = Store.ACTIONS.SET_RENDER_STATUS, index = target.index, status = "pending" })
				dispatch({ type = Store.ACTIONS.SET_RENDERING, rendering = true, progress = i - 1, total = #targets })

				local ok, img = renderOne(target.entry.instance, renderSettings()):await()
				dispatch({
					type = Store.ACTIONS.SET_RENDER_STATUS,
					index = target.index,
					status = if ok then "ok" else "fail",
					image = if ok then img else nil,
				})
				dispatch({ type = Store.ACTIONS.SET_RENDERING, rendering = true, progress = i, total = #targets })
				task.wait()
			end
			dispatch({ type = Store.ACTIONS.SET_RENDERING, rendering = false, progress = 0, total = 0 })
			renderingRef.current = false
		end)
	end

	-- Export all
	local function doExport()
		local parts = exportAll(state.models)
		if #parts > 0 then
			pcall(function()
				Selection:Set(parts)
			end)
		end
	end

	-- Export only the currently previewed model
	local function exportPreview()
		local idx = state.previewModelIndex
		if not idx then
			return
		end
		local entry = state.models[idx]
		if not entry or not entry.image then
			return
		end
		local parts = exportAll({ entry })
		if #parts > 0 then
			pcall(function()
				Selection:Set(parts)
			end)
		end
	end

	-- Re-render only the currently previewed model
	local function rerenderPreview()
		if renderingRef.current then
			return
		end
		local idx = state.previewModelIndex
		if not idx then
			return
		end
		local entry = state.models[idx]
		if not entry or entry.isExported then
			return
		end

		renderingRef.current = true
		dispatch({ type = Store.ACTIONS.SET_RENDERING, rendering = true, progress = 0, total = 1 })
		dispatch({ type = Store.ACTIONS.SET_RENDER_STATUS, index = idx, status = "pending" })

		task.spawn(function()
			local ok, img = renderOne(entry.instance, renderSettings()):await()
			dispatch({
				type = Store.ACTIONS.SET_RENDER_STATUS,
				index = idx,
				status = if ok then "ok" else "fail",
				image = if ok then img else nil,
			})
			dispatch({ type = Store.ACTIONS.SET_RENDERING, rendering = false, progress = 0, total = 0 })
			renderingRef.current = false
			if ok and img then
				dispatch({
					type = Store.ACTIONS.SET_PREVIEW_IMAGE,
					image = img,
					title = entry.instance.Name,
					index = idx,
				})
			end
		end)
	end

	-- Preset handlers
	local function openSaveModal()
		dispatch({ type = Store.ACTIONS.SET_NAME_INPUT_MODAL, value = { mode = "save" } })
	end

	local function openRenameModal(index: number)
		local preset = state.presets[index]
		if not preset then
			return
		end
		dispatch({
			type = Store.ACTIONS.SET_NAME_INPUT_MODAL,
			value = { mode = "rename", targetIndex = index, initialName = preset.name },
		})
	end

	local function closeNameInputModal()
		dispatch({ type = Store.ACTIONS.SET_NAME_INPUT_MODAL, value = nil })
	end

	local function confirmNameInput(name: string)
		local modal = state.nameInputModal
		if not modal then
			return
		end
		local next = table.clone(state.presets)
		if modal.mode == "save" then
			table.insert(next, {
				name = name,
				yaw = state.yaw,
				pitch = state.pitch,
				roll = state.roll,
				fov = state.fov,
				cameraDistance = state.cameraDistance,
				bgMode = state.bgMode,
				bgColor = state.bgColor,
				exportSize = state.exportSize,
				outline = state.outline,
				dropShadow = state.dropShadow,
				innerShadow = state.innerShadow,
				outerGlow = state.outerGlow,
				chromaticAberration = state.chromaticAberration,
			})
		elseif modal.mode == "rename" and modal.targetIndex then
			local entry = table.clone(next[modal.targetIndex])
			entry.name = name
			next[modal.targetIndex] = entry
		end
		dispatch({ type = Store.ACTIONS.SET_PRESETS, value = next })
	end

	local function applyPreset(index: number)
		local preset = state.presets[index]
		if not preset then
			return
		end
		dispatch({ type = Store.ACTIONS.APPLY_PRESET, value = preset })
	end

	local function deletePreset(index: number)
		setDeleteConfirmIndex(index)
	end

	local function confirmDeletePreset()
		if not deleteConfirmIndex then
			return
		end
		local next = table.clone(state.presets)
		table.remove(next, deleteConfirmIndex)
		dispatch({ type = Store.ACTIONS.SET_PRESETS, value = next })
	end

	-- Trackball handler
	local function onTrackball(dYaw: number, dPitch: number)
		dispatch({
			type = Store.ACTIONS.SET_CAMERA,
			yaw = state.yaw + dYaw,
			pitch = state.pitch + dPitch,
			fov = state.fov,
		})
	end

	-- Translate handler (Shift+drag)
	local function onTranslate(dx: number, dy: number, dz: number)
		dispatch({
			type = Store.ACTIONS.SET_CAMERA_OFFSET,
			x = state.cameraOffsetX + dx,
			y = state.cameraOffsetY + dy,
			z = state.cameraOffsetZ + dz,
		})
	end

	-- Scroll-to-zoom handler
	local function onScroll(direction: number)
		local ctrlDown = isCtrlDown()

		if ctrlDown then
			local newFov = math.clamp(state.fov + direction * 3, 1, 120)
			dispatch({ type = Store.ACTIONS.SET_FOV, value = newFov })
		else
			local newDistance = math.clamp(state.cameraDistance - direction * 0.1, 0.1, 3)
			dispatch({ type = Store.ACTIONS.SET_CAMERA_DISTANCE, value = newDistance })
		end
	end

	local function onResetCamera()
		dispatch({
			type = Store.ACTIONS.SET_CAMERA,
			yaw = Store.DEFAULT_STATE.yaw,
			pitch = Store.DEFAULT_STATE.pitch,
			fov = Store.DEFAULT_STATE.fov,
			roll = 0,
			resetOffset = true,
		})
		dispatch({ type = Store.ACTIONS.SET_CAMERA_DISTANCE, value = Store.DEFAULT_STATE.cameraDistance })
	end

	local totalCount = 0
	for _, entry in ipairs(state.models) do
		if not entry.isExported then
			totalCount += 1
		end
	end

	local hasRenders = false
	for _, entry in ipairs(state.models) do
		if entry.image then
			hasRenders = true
			break
		end
	end

	local hasRenderableSelected = false
	for _, idx in ipairs(state.selectedModelIndices) do
		local entry = state.models[idx]
		if entry and not entry.isExported then
			hasRenderableSelected = true
			break
		end
	end

	-- Adjacent rendered models for prev/next navigation in preview modal
	local prevRenderedIndex = nil
	local nextRenderedIndex = nil
	local previewIdx = state.previewModelIndex
	if previewIdx then
		for i = previewIdx - 1, 1, -1 do
			if state.models[i] and state.models[i].image then
				prevRenderedIndex = i
				break
			end
		end
		for i = previewIdx + 1, #state.models do
			if state.models[i] and state.models[i].image then
				nextRenderedIndex = i
				break
			end
		end
	end

	return e(StudioComponents.PluginProvider, {
		Plugin = props.plugin,
	}, {
		background = e(StudioComponents.Background, {
			Size = UDim2.fromScale(1, 1),
		}, {
			inputCapture = e("TextButton", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Active = true,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 9999,
				[React.Event.InputBegan] = onWidgetInputBegan,
				[React.Event.InputEnded] = onWidgetInputEnded,
			}, {
				toolbar = e(ToolbarStrip, {
					rendering = state.rendering,
					onRender = startRenderSelected,
					onRenderAll = startRenderAll,
					onExport = doExport,
					onHelp = function()
						setHelpOpen(true)
					end,
					renderDisabled = not hasRenderableSelected,
					renderAllDisabled = totalCount == 0,
					exportDisabled = not hasRenders,
				}),
				content = e("Frame", {
					Size = UDim2.new(1, 0, 1, -36),
					Position = UDim2.fromOffset(0, 36),
					BackgroundTransparency = 1,
				}, {
					mainSplitter = e(StudioComponents.Splitter, {
						Alpha = sidebarAlpha,
						OnChanged = setSidebarAlpha,
						FillDirection = Enum.FillDirection.Horizontal,
					}, {
						Side0 = e(StudioComponents.Splitter, {
							Alpha = modelStripAlpha,
							OnChanged = setModelStripAlpha,
							FillDirection = Enum.FillDirection.Vertical,
						}, {
							Side0 = e(PreviewViewport, {
								entry = activeEntry,
								yaw = state.yaw,
								pitch = state.pitch,
								roll = state.roll,
								fov = state.fov,
								cameraDistance = state.cameraDistance,
								offsetX = state.cameraOffsetX,
								offsetY = state.cameraOffsetY,
								offsetZ = state.cameraOffsetZ,
								onTrackball = onTrackball,
								onTranslate = onTranslate,
								onScroll = onScroll,
								onResetCamera = onResetCamera,
								isShiftDown = isShiftDown,
								shiftDown = shiftDown,
								animations = state.animations,
								activeAnimationIndex = state.activeAnimationIndex,
								animationPlaying = state.animationPlaying,
								animationTimePosition = state.animationTimePosition,
								animationLength = state.animationLength,
								onSelectAnimation = onSelectAnimation,
								onSetPlaying = onSetAnimationPlaying,
								onSetTimePosition = onSetAnimationTimePosition,
								onSetLength = onSetAnimationLength,
							}),
							Side1 = e(ModelStrip, {
								models = state.models,
								selectedModelIndices = state.selectedModelIndices,
								yaw = state.yaw,
								pitch = state.pitch,
								roll = state.roll,
								fov = state.fov,
								cameraDistance = state.cameraDistance,
								offsetX = state.cameraOffsetX,
								offsetY = state.cameraOffsetY,
								offsetZ = state.cameraOffsetZ,
								onSelectModel = function(index)
									local ctrlDown = isCtrlDown()
									if ctrlDown then
										-- Toggle this index in the selection
										local next = {}
										local found = false
										for _, i in ipairs(state.selectedModelIndices) do
											if i == index then
												found = true
											else
												table.insert(next, i)
											end
										end
										if not found then
											table.insert(next, index)
										end
										dispatch({ type = Store.ACTIONS.SET_SELECTION, value = next })
									else
										dispatch({ type = Store.ACTIONS.SET_SELECTION, value = { index } })
									end
								end,
								onPreviewModel = function(index)
									local entry = state.models[index]
									if entry and entry.image then
										dispatch({
											type = Store.ACTIONS.SET_PREVIEW_IMAGE,
											image = entry.image,
											title = entry.instance.Name,
											index = index,
										})
									end
								end,
							}),
						}),
						Side1 = e(Sidebar, {
							state = state,
							dispatch = dispatch,
							onSavePreset = openSaveModal,
							onApplyPreset = applyPreset,
							onRenamePreset = openRenameModal,
							onDeletePreset = deletePreset,
						}),
					}),
				}),
				renderOverlay = if state.rendering and state.renderTotal > 0
					then e(Darkener, {}, {
						progressBox = e("Frame", {
							Size = UDim2.fromOffset(260, 64),
							Position = UDim2.fromScale(0.5, 0.5),
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundColor3 = Color3.fromRGB(40, 40, 40),
							BorderSizePixel = 0,
						}, {
							label = e("TextLabel", {
								Text = string.format("Rendering %d / %d...", state.renderProgress, state.renderTotal),
								Size = UDim2.new(1, 0, 0, 20),
								Position = UDim2.fromOffset(0, 12),
								BackgroundTransparency = 1,
								TextColor3 = Color3.fromRGB(220, 220, 220),
								TextSize = 13,
								Font = Enum.Font.SourceSansSemibold,
								TextXAlignment = Enum.TextXAlignment.Center,
								ZIndex = 20,
							}),
							bar = e(StudioComponents.ProgressBar, {
								Value = state.renderProgress / state.renderTotal,
								Formatter = function(_, _)
									return "" -- this is intentional to hide the text
								end,
								Size = UDim2.new(1, -32, 0, 6),
								Position = UDim2.fromOffset(16, 40),
							}),
						}),
					})
					else nil,
				imagePreview = if state.previewImage
					then e(ImagePreviewModal, {
						image = state.previewImage,
						title = state.previewTitle or "Preview",
						rendering = state.rendering,
						hasPrev = prevRenderedIndex ~= nil,
						hasNext = nextRenderedIndex ~= nil,
						onClose = function()
							dispatch({
								type = Store.ACTIONS.SET_PREVIEW_IMAGE,
								image = nil,
								title = nil,
								index = nil,
							})
						end,
						onExport = exportPreview,
						onRerender = rerenderPreview,
						onPrev = if prevRenderedIndex
							then function()
								local entry = state.models[prevRenderedIndex]
								dispatch({
									type = Store.ACTIONS.SET_PREVIEW_IMAGE,
									image = entry.image,
									title = entry.instance.Name,
									index = prevRenderedIndex,
								})
							end
							else nil,
						onNext = if nextRenderedIndex
							then function()
								local entry = state.models[nextRenderedIndex]
								dispatch({
									type = Store.ACTIONS.SET_PREVIEW_IMAGE,
									image = entry.image,
									title = entry.instance.Name,
									index = nextRenderedIndex,
								})
							end
							else nil,
					})
					else nil,
				deleteConfirmModal = if deleteConfirmIndex ~= nil
					then e(ConfirmModal, {
						title = "Delete Preset",
						message = `Delete "{if state.presets[deleteConfirmIndex]
							then state.presets[deleteConfirmIndex].name
							else ""}"?`,
						confirmLabel = "Delete",
						onConfirm = confirmDeletePreset,
						onClose = function()
							setDeleteConfirmIndex(nil)
						end,
					})
					else nil,
				nameInputModal = if state.nameInputModal ~= nil
					then e(NameInputModal, {
						mode = state.nameInputModal.mode,
						initialName = state.nameInputModal.initialName,
						onConfirm = confirmNameInput,
						onClose = closeNameInputModal,
					})
					else nil,
				colorPickerModal = if state.colorPickerTarget ~= nil
					then (function()
						local A = Store.ACTIONS
						local target = state.colorPickerTarget
						local title, color
						local onPickerColor: (Color3) -> ()
						if target == "outline" then
							title = "Outline Color"
							color = state.outline.color
							onPickerColor = function(c)
								dispatch({ type = A.SET_OUTLINE, value = { color = c } })
							end
						elseif target == "shadow" then
							title = "Shadow Color"
							color = state.dropShadow.color
							onPickerColor = function(c)
								dispatch({ type = A.SET_DROP_SHADOW, value = { color = c } })
							end
						elseif target == "inner" then
							title = "Inner Shadow Color"
							color = state.innerShadow.color
							onPickerColor = function(c)
								dispatch({ type = A.SET_INNER_SHADOW, value = { color = c } })
							end
						elseif target == "background" then
							title = "Background Color"
							color = state.bgColor
							onPickerColor = function(c)
								dispatch({ type = A.SET_BG_COLOR, value = c })
							end
						else
							title = "Outer Glow Color"
							color = state.outerGlow.color
							onPickerColor = function(c)
								dispatch({ type = A.SET_OUTER_GLOW, value = { color = c } })
							end
						end
						return e(ColorPickerModal, {
							title = title,
							color = color,
							onColorChanged = onPickerColor,
							onClose = function()
								dispatch({ type = A.SET_COLOR_PICKER_TARGET, value = nil })
							end,
						})
					end)()
					else nil,
				helpShortcutsModal = if helpOpen
					then e(HelpShortcutsModal, {
						onClose = function()
							setHelpOpen(false)
						end,
					})
					else nil,
			}),
		}),
	})
end

return App

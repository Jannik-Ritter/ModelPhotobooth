local Packages = script.Parent.Parent.Packages
local React = require(Packages._Index["jsdotlua_react@17.2.1"]["react"])
local StudioComponents = require(Packages.studiocomponents)

local Selection = game:GetService("Selection")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")

local Store = require(script.Parent.Store)
local captureOne = require(script.Parent.lib.captureOne)
local exportAll = require(script.Parent.lib.exportAll)
local PresetSerialization = require(script.Parent.lib.presetSerialization)
local ToolbarStrip = require(script.Parent.components.ToolbarStrip)
local PreviewViewport = require(script.Parent.components.PreviewViewport)
local ModelStrip = require(script.Parent.components.ModelStrip)
local Sidebar = require(script.Parent.components.Sidebar)
local ImagePreviewModal = require(script.Parent.components.ImagePreviewModal)
local ColorPickerModal = require(script.Parent.components.ColorPickerModal)
local NameInputModal = require(script.Parent.components.NameInputModal)
local ConfirmModal = require(script.Parent.components.ConfirmModal)
local Darkener = require(script.Parent.components.Darkener)

local e = React.createElement
local MPB_TAG = "_MPBIcon"

type Props = {
	plugin: any,
}

local function App(props: Props)
	local state, dispatch = React.useReducer(Store.reducer, Store.DEFAULT_STATE)
	local capturingRef = React.useRef(false)
	local modelsRef = React.useRef(Store.DEFAULT_STATE.models)
	local deleteConfirmIndex, setDeleteConfirmIndex = React.useState(nil :: number?)

	-- Keep modelsRef current so the selection listener can access latest captures
	React.useEffect(function()
		modelsRef.current = state.models
	end)

	-- Selection listener
	React.useEffect(function()
		local function refresh()
			-- Build a lookup of existing entries by instance to preserve captures
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
						status = "ok" :: Store.CaptureStatus,
						image = nil,
						isExported = true,
					})
				elseif obj:IsA("Model") or obj:IsA("BasePart") then
					local prev = existing[obj]
					table.insert(models, {
						instance = obj,
						status = if prev then prev.status else "idle" :: Store.CaptureStatus,
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

	local function captureSettings()
		return {
			yaw = state.yaw,
			pitch = state.pitch,
			fov = state.fov,
			cameraDistance = state.cameraDistance,
			outline = state.outline,
			dropShadow = state.dropShadow,
			innerShadow = state.innerShadow,
			outerGlow = state.outerGlow,
			chromaticAberration = state.chromaticAberration,
			bgMode = state.bgMode,
			bgColor = state.bgColor,
			exportSize = state.exportSize,
		}
	end

	-- Capture the currently selected models
	local function startCaptureSelected()
		if capturingRef.current then
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
		capturingRef.current = true
		dispatch({ type = Store.ACTIONS.SET_CAPTURING, capturing = true, progress = 0, total = #targets })

		task.spawn(function()
			for i, target in ipairs(targets) do
				dispatch({ type = Store.ACTIONS.SET_CAPTURE_STATUS, index = target.index, status = "pending" })
				dispatch({ type = Store.ACTIONS.SET_CAPTURING, capturing = true, progress = i - 1, total = #targets })

				local img = captureOne(target.entry.instance, captureSettings())
				dispatch({
					type = Store.ACTIONS.SET_CAPTURE_STATUS,
					index = target.index,
					status = if img then "ok" else "fail",
					image = img,
				})
				dispatch({ type = Store.ACTIONS.SET_CAPTURING, capturing = true, progress = i, total = #targets })
				task.wait()
			end
			dispatch({ type = Store.ACTIONS.SET_CAPTURING, capturing = false, progress = 0, total = 0 })
			capturingRef.current = false
		end)
	end

	-- Capture all non-exported models
	local function startCaptureAll()
		if capturingRef.current then
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
		capturingRef.current = true
		dispatch({ type = Store.ACTIONS.SET_CAPTURING, capturing = true, progress = 0, total = #targets })

		task.spawn(function()
			for i, target in ipairs(targets) do
				dispatch({ type = Store.ACTIONS.SET_CAPTURE_STATUS, index = target.index, status = "pending" })
				dispatch({ type = Store.ACTIONS.SET_CAPTURING, capturing = true, progress = i - 1, total = #targets })

				local img = captureOne(target.entry.instance, captureSettings())
				dispatch({
					type = Store.ACTIONS.SET_CAPTURE_STATUS,
					index = target.index,
					status = if img then "ok" else "fail",
					image = img,
				})
				dispatch({ type = Store.ACTIONS.SET_CAPTURING, capturing = true, progress = i, total = #targets })
				task.wait()
			end
			dispatch({ type = Store.ACTIONS.SET_CAPTURING, capturing = false, progress = 0, total = 0 })
			capturingRef.current = false
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
		if not idx then return end
		local entry = state.models[idx]
		if not entry or not entry.image then return end
		local parts = exportAll({ entry })
		if #parts > 0 then
			pcall(function()
				Selection:Set(parts)
			end)
		end
	end

	-- Recapture only the currently previewed model
	local function recapturePreview()
		if capturingRef.current then return end
		local idx = state.previewModelIndex
		if not idx then return end
		local entry = state.models[idx]
		if not entry or entry.isExported then return end

		capturingRef.current = true
		dispatch({ type = Store.ACTIONS.SET_CAPTURING, capturing = true, progress = 0, total = 1 })
		dispatch({ type = Store.ACTIONS.SET_CAPTURE_STATUS, index = idx, status = "pending" })

		task.spawn(function()
			local img = captureOne(entry.instance, captureSettings())
			dispatch({
				type = Store.ACTIONS.SET_CAPTURE_STATUS,
				index = idx,
				status = if img then "ok" else "fail",
				image = img,
			})
			dispatch({ type = Store.ACTIONS.SET_CAPTURING, capturing = false, progress = 0, total = 0 })
			capturingRef.current = false
			if img then
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
		if not preset then return end
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
		if not modal then return end
		local next = table.clone(state.presets)
		if modal.mode == "save" then
			table.insert(next, {
				name = name,
				yaw = state.yaw,
				pitch = state.pitch,
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
		if not preset then return end
		dispatch({ type = Store.ACTIONS.APPLY_PRESET, value = preset })
	end

	local function deletePreset(index: number)
		setDeleteConfirmIndex(index)
	end

	local function confirmDeletePreset()
		if not deleteConfirmIndex then return end
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

	-- Scroll-to-zoom handler
	local function onScroll(newFov: number)
		dispatch({ type = Store.ACTIONS.SET_FOV, value = newFov })
	end

	local totalCount = 0
	for _, entry in ipairs(state.models) do
		if not entry.isExported then
			totalCount += 1
		end
	end

	local hasCaptures = false
	for _, entry in ipairs(state.models) do
		if entry.image then
			hasCaptures = true
			break
		end
	end

	local hasCapturableSelected = false
	for _, idx in ipairs(state.selectedModelIndices) do
		local entry = state.models[idx]
		if entry and not entry.isExported then
			hasCapturableSelected = true
			break
		end
	end

	-- Active model entry (last in selection for preview)
	local focusedIndex = state.selectedModelIndices[#state.selectedModelIndices]
	local activeEntry = if focusedIndex then state.models[focusedIndex] else nil

	-- Adjacent captured models for prev/next navigation in preview modal
	local prevCapturedIndex = nil
	local nextCapturedIndex = nil
	local previewIdx = state.previewModelIndex
	if previewIdx then
		for i = previewIdx - 1, 1, -1 do
			if state.models[i] and state.models[i].image then
				prevCapturedIndex = i
				break
			end
		end
		for i = previewIdx + 1, #state.models do
			if state.models[i] and state.models[i].image then
				nextCapturedIndex = i
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
			toolbar = e(ToolbarStrip, {
				capturing = state.capturing,
				onCapture = startCaptureSelected,
				onCaptureAll = startCaptureAll,
				onExport = doExport,
				captureDisabled = not hasCapturableSelected,
				captureAllDisabled = totalCount == 0,
				exportDisabled = not hasCaptures,
			}),
			content = e("Frame", {
				Size = UDim2.new(1, 0, 1, -36),
				Position = UDim2.fromOffset(0, 36),
				BackgroundTransparency = 1,
			}, {
				preview = e(PreviewViewport, {
					entry = activeEntry,
					yaw = state.yaw,
					pitch = state.pitch,
					fov = state.fov,
					cameraDistance = state.cameraDistance,
					onTrackball = onTrackball,
					onScroll = onScroll,
				}),
				modelStrip = e(ModelStrip, {
					models = state.models,
					selectedModelIndices = state.selectedModelIndices,
					yaw = state.yaw,
					pitch = state.pitch,
					fov = state.fov,
					onSelectModel = function(index)
						local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
							or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
						if ctrl then
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
				sidebar = e(Sidebar, {
					state = state,
					dispatch = dispatch,
					onSavePreset = openSaveModal,
					onApplyPreset = applyPreset,
					onRenamePreset = openRenameModal,
					onDeletePreset = deletePreset,
				}),
			}),
			captureOverlay = if state.capturing and state.captureTotal > 0
				then e(Darkener, {}, {
					progressBox = e("Frame", {
						Size = UDim2.fromOffset(260, 64),
						Position = UDim2.fromScale(0.5, 0.5),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(40, 40, 40),
						BorderSizePixel = 0,
					}, {
						label = e("TextLabel", {
							Text = string.format("Capturing %d / %d...", state.captureProgress, state.captureTotal),
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
							Value = state.captureProgress / state.captureTotal,
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
					capturing = state.capturing,
					hasPrev = prevCapturedIndex ~= nil,
					hasNext = nextCapturedIndex ~= nil,
					onClose = function()
						dispatch({
							type = Store.ACTIONS.SET_PREVIEW_IMAGE,
							image = nil,
							title = nil,
							index = nil,
						})
					end,
					onExport = exportPreview,
					onRecapture = recapturePreview,
					onPrev = if prevCapturedIndex then function()
						local entry = state.models[prevCapturedIndex]
						dispatch({
							type = Store.ACTIONS.SET_PREVIEW_IMAGE,
							image = entry.image,
							title = entry.instance.Name,
							index = prevCapturedIndex,
						})
					end else nil,
					onNext = if nextCapturedIndex then function()
						local entry = state.models[nextCapturedIndex]
						dispatch({
							type = Store.ACTIONS.SET_PREVIEW_IMAGE,
							image = entry.image,
							title = entry.instance.Name,
							index = nextCapturedIndex,
						})
					end else nil,
				})
				else nil,
			deleteConfirmModal = if deleteConfirmIndex ~= nil
				then e(ConfirmModal, {
					title = "Delete Preset",
					message = `Delete "{if state.presets[deleteConfirmIndex] then state.presets[deleteConfirmIndex].name else ""}"?`,
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
					local title, color, action
					if target == "outline" then
						title = "Outline Color"
						color = state.outline.color
						action = A.SET_OUTLINE
					elseif target == "shadow" then
						title = "Shadow Color"
						color = state.dropShadow.color
						action = A.SET_DROP_SHADOW
					elseif target == "inner" then
						title = "Inner Shadow Color"
						color = state.innerShadow.color
						action = A.SET_INNER_SHADOW
					else
						title = "Outer Glow Color"
						color = state.outerGlow.color
						action = A.SET_OUTER_GLOW
					end
					return e(ColorPickerModal, {
						title = title,
						color = color,
						onColorChanged = function(c)
							dispatch({ type = action, value = { color = c } })
						end,
						onClose = function()
							dispatch({ type = A.SET_COLOR_PICKER_TARGET, value = nil })
						end,
					})
				end)()
				else nil,
		}),
	})
end

return App

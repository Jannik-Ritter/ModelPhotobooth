local Packages = script.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local Store = require(script.Parent.Store)
local StoreContext = require(script.Parent.StoreContext)
local constants = require(script.Parent.constants)

local useToasts = require(script.Parent.hooks.useToasts)
local useWidgetInput = require(script.Parent.hooks.useWidgetInput)
local useSelectionSync = require(script.Parent.hooks.useSelectionSync)
local usePresetPersistence = require(script.Parent.hooks.usePresetPersistence)
local useAnimationDetection = require(script.Parent.hooks.useAnimationDetection)
local useRendering = require(script.Parent.hooks.useRendering)
local useExporting = require(script.Parent.hooks.useExporting)
local useUploading = require(script.Parent.hooks.useUploading)
local usePreviewNavigation = require(script.Parent.hooks.usePreviewNavigation)
local usePresetActions = require(script.Parent.hooks.usePresetActions)

local MainContent = require(script.Parent.components.layout.MainContent)
local ModalManager = require(script.Parent.components.modals.ModalManager)

local e = React.createElement

type Props = {
	plugin: any,
}

local function App(props: Props)
	local state, dispatch = React.useReducer(Store.reducer, Store.DEFAULT_STATE)
	local renderingRef = React.useRef(false)
	local modelsRef = React.useRef(Store.DEFAULT_STATE.models)
	local animationPlayingRef = React.useRef(false)
	local activeAnimationIndexRef = React.useRef(nil :: number?)
	local uploadingRef = React.useRef(false)

	React.useEffect(function() modelsRef.current = state.models end)

	local toasts = useToasts()
	local widgetInput = useWidgetInput(dispatch, animationPlayingRef, activeAnimationIndexRef)
	useSelectionSync(dispatch, modelsRef)
	usePresetPersistence(dispatch, state.presets, props.plugin)

	local focusedIndex = state.selectedModelIndices[#state.selectedModelIndices]
	local activeEntry = if focusedIndex then state.models[focusedIndex] else nil
	local activeInstance = if activeEntry then activeEntry.instance else nil

	useAnimationDetection(dispatch, activeInstance, animationPlayingRef, activeAnimationIndexRef)

	React.useEffect(function()
		animationPlayingRef.current = state.animationPlaying
	end)
	React.useEffect(function()
		activeAnimationIndexRef.current = state.activeAnimationIndex
	end)

	local rendering = useRendering(state, dispatch, renderingRef, animationPlayingRef, toasts.addToast)
	local exporting = useExporting(state, toasts.addToast)
	local uploading = useUploading(state, uploadingRef)
	local previewNav = usePreviewNavigation(state)
	local presets = usePresetActions(state, dispatch)

	local sidebarAlpha, setSidebarAlpha = React.useState(0.65)
	local modelStripAlpha, setModelStripAlpha = React.useState(0.82)
	local stripTab, setStripTab = React.useState("Models")
	local helpOpen, setHelpOpen = React.useState(
		if props.plugin:GetSetting("hasSeenHelp") ~= true then "General" else false
	)
	local deleteConfirmIndex, setDeleteConfirmIndex = React.useState(nil :: number?)

	local function onTrackball(dYaw: number, dPitch: number)
		dispatch({
			type = Store.ACTIONS.SET_CAMERA,
			yaw = state.yaw + dYaw,
			pitch = state.pitch + dPitch,
			fov = state.fov,
		})
	end

	local function onTranslate(dx: number, dy: number, dz: number)
		dispatch({
			type = Store.ACTIONS.SET_CAMERA_OFFSET,
			x = math.clamp(state.cameraOffsetX + dx, constants.CAMERA_OFFSET_MIN, constants.CAMERA_OFFSET_MAX),
			y = math.clamp(state.cameraOffsetY + dy, constants.CAMERA_OFFSET_MIN, constants.CAMERA_OFFSET_MAX),
			z = math.clamp(state.cameraOffsetZ + dz, constants.CAMERA_OFFSET_MIN, constants.CAMERA_OFFSET_MAX),
		})
	end

	local function onScroll(direction: number)
		if widgetInput.isCtrlDown() then
			local newFov = math.clamp(state.fov + direction * constants.FOV_SCROLL_STEP, constants.FOV_MIN, constants.FOV_MAX)
			dispatch({ type = Store.ACTIONS.SET_FOV, value = newFov })
		else
			local newDistance = math.clamp(
				state.cameraDistance - direction * constants.CAMERA_DISTANCE_SCROLL_STEP,
				constants.CAMERA_DISTANCE_MIN,
				constants.CAMERA_DISTANCE_MAX
			)
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

	local function onSelectModel(index: number)
		if widgetInput.isCtrlDown() then
			local next = {}
			local found = false
			for _, i in ipairs(state.selectedModelIndices) do
				if i == index then
					found = true
				else
					table.insert(next, i)
				end
			end
			if not found then table.insert(next, index) end
			dispatch({ type = Store.ACTIONS.SET_SELECTION, value = next })
		else
			dispatch({ type = Store.ACTIONS.SET_SELECTION, value = { index } })
			dispatch({ type = Store.ACTIONS.SET_ACTIVE_ANIMATION, value = nil })
		end
	end

	local function onPreviewModel(index: number)
		local entry = state.models[index]
		if entry and entry.image then
			dispatch({
				type = Store.ACTIONS.SET_PREVIEW_IMAGE,
				image = entry.image,
				title = entry.instance.Name,
				index = index,
				historyIndex = nil,
			})
		end
	end

	local function onPreviewRender(index: number)
		local entry = state.renderHistory[index]
		if entry then
			dispatch({
				type = Store.ACTIONS.SET_PREVIEW_IMAGE,
				image = entry.image,
				title = entry.modelName,
				index = nil,
				historyIndex = index,
			})
		end
	end

	local function makePreviewNavFn(fromHistory: boolean, backward: boolean)
		return function()
			local idx = if fromHistory
				then (if backward then previewNav.prevHistoryIndex else previewNav.nextHistoryIndex)
				else (if backward then previewNav.prevRenderedIndex else previewNav.nextRenderedIndex)
			if not idx then return end
			if fromHistory then
				local entry = state.renderHistory[idx]
				dispatch({
					type = Store.ACTIONS.SET_PREVIEW_IMAGE,
					image = entry.image,
					title = entry.modelName,
					index = nil,
					historyIndex = idx,
				})
			else
				local entry = state.models[idx]
				dispatch({
					type = Store.ACTIONS.SET_PREVIEW_IMAGE,
					image = entry.image,
					title = entry.instance.Name,
					index = idx,
					historyIndex = nil,
				})
			end
		end
	end

	local deleteConfirmName = ""
	if deleteConfirmIndex then
		local preset = state.presets[deleteConfirmIndex]
		if preset then deleteConfirmName = preset.name end
	end

	local modals = ModalManager({
		state = state,
		dispatch = dispatch,
		rendering = state.rendering,
		renderProgress = state.renderProgress,
		renderTotal = state.renderTotal,
		uploading = uploading.uploading,
		uploadProgress = uploading.uploadProgress,
		uploadTotal = uploading.uploadTotal,
		uploadResults = uploading.uploadResults,
		deleteConfirmIndex = deleteConfirmIndex,
		deleteConfirmName = deleteConfirmName,
		helpOpen = helpOpen,
		hasPrevPreview = if previewNav.previewFromHistory then previewNav.prevHistoryIndex ~= nil else previewNav.prevRenderedIndex ~= nil,
		hasNextPreview = if previewNav.previewFromHistory then previewNav.nextHistoryIndex ~= nil else previewNav.nextRenderedIndex ~= nil,
		hideRerender = previewNav.previewFromHistory,
		onClosePreview = function()
			dispatch({ type = Store.ACTIONS.SET_PREVIEW_IMAGE, image = nil, title = nil, index = nil, historyIndex = nil })
		end,
		onExportPreview = exporting.exportPreviewImage,
		onUploadPreview = uploading.uploadPreviewImage,
		onRerenderPreview = rendering.rerenderPreview,
		onPrevPreview = makePreviewNavFn(previewNav.previewFromHistory, true),
		onNextPreview = makePreviewNavFn(previewNav.previewFromHistory, false),
		onCloseUploadResults = function() uploading.setUploadResults(nil) end,
		onHelpFromUpload = function() uploading.setUploadResults(nil); setHelpOpen("Common Issues") end,
		onCloseDeleteConfirm = function() setDeleteConfirmIndex(nil) end,
		onConfirmDeletePreset = function()
			if deleteConfirmIndex then presets.confirmDeletePreset(deleteConfirmIndex) end
			setDeleteConfirmIndex(nil)
		end,
		onCloseNameInput = presets.closeNameInputModal,
		onConfirmNameInput = presets.confirmNameInput,
		onCloseColorPicker = function()
			dispatch({ type = Store.ACTIONS.SET_COLOR_PICKER_TARGET, value = nil })
		end,
		onCloseHelp = function()
			props.plugin:SetSetting("hasSeenHelp", true)
			setHelpOpen(false)
		end,
		toasts = toasts.toasts,
		onRemoveToast = toasts.removeToast,
		onHelpFromToast = function() setHelpOpen("Common Issues") end,
	})

	return e(StudioComponents.PluginProvider, { Plugin = props.plugin }, {
		storeProvider = e(StoreContext.Provider, {
			value = { state = state, dispatch = dispatch },
		}, {
			mainContent = e(MainContent, {
				inputCaptureProps = widgetInput.inputCaptureProps,
				sidebarAlpha = sidebarAlpha,
				setSidebarAlpha = setSidebarAlpha,
				modelStripAlpha = modelStripAlpha,
				setModelStripAlpha = setModelStripAlpha,
				stripTab = stripTab,
				setStripTab = setStripTab,
				shiftDown = widgetInput.shiftDown,
				isShiftDown = widgetInput.isShiftDown,
				activeEntry = activeEntry,
				onTrackball = onTrackball,
				onTranslate = onTranslate,
				onScroll = onScroll,
				onResetCamera = onResetCamera,
				onSelectAnimation = function(index)
					dispatch({ type = Store.ACTIONS.SET_ACTIVE_ANIMATION, value = index })
				end,
				onSetPlaying = function(playing)
					dispatch({ type = Store.ACTIONS.SET_ANIMATION_PLAYING, value = playing })
				end,
				onSetTimePosition = function(time)
					dispatch({ type = Store.ACTIONS.SET_ANIMATION_TIME, value = time })
				end,
				onSetLength = function(length)
					dispatch({ type = Store.ACTIONS.SET_ANIMATION_LENGTH, value = length })
				end,
				onSelectModel = onSelectModel,
				onPreviewModel = onPreviewModel,
				onPreviewRender = onPreviewRender,
				onSavePreset = presets.openSaveModal,
				onApplyPreset = presets.applyPreset,
				onRenamePreset = presets.openRenameModal,
				onDeletePreset = function(index) setDeleteConfirmIndex(index) end,
				onRender = rendering.startRenderSelected,
				onRenderAll = rendering.startRenderAll,
				onExport = exporting.doExport,
				onUploadAll = uploading.doUploadAll,
				onHelp = function() setHelpOpen("General") end,
			}),
			modals = e("Folder", {}, modals),
		}),
	})
end

return App

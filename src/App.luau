local Packages = script.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local Store = require(script.Parent.Store)
local StoreContext = require(script.Parent.StoreContext)

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
local useCameraInput = require(script.Parent.hooks.useCameraInput)
local useModalHandlers = require(script.Parent.hooks.useModalHandlers)

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

	React.useEffect(function()
		modelsRef.current = state.models
	end)

	local toasts = useToasts()
	local widgetInput = useWidgetInput(dispatch, animationPlayingRef, activeAnimationIndexRef)
	useSelectionSync(dispatch, modelsRef)
	usePresetPersistence(dispatch, state.presets, props.plugin)

	local focusedIndex = state.selectedModelIndices[#state.selectedModelIndices]
	local activeEntry = if focusedIndex then state.models[focusedIndex] else nil
	local activeInstance = if activeEntry then activeEntry.instance else nil

	useAnimationDetection(dispatch, activeInstance)

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
	local helpOpen, setHelpOpen =
		React.useState(if props.plugin:GetSetting("hasSeenHelp") ~= true then "General" else nil :: string?)
	local deleteConfirmIndex, setDeleteConfirmIndex = React.useState(nil :: number?)

	local cameraInput = useCameraInput(state, dispatch, widgetInput.isCtrlDown)

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
			if not found then
				table.insert(next, index)
			end
			dispatch({ type = Store.ACTIONS.SET_SELECTION, value = next })
		else
			local alreadySelected = #state.selectedModelIndices == 1 and state.selectedModelIndices[1] == index
			dispatch({ type = Store.ACTIONS.SET_SELECTION, value = { index } })
			if not alreadySelected then
				dispatch({ type = Store.ACTIONS.SET_ACTIVE_ANIMATION, value = nil })
			end
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

	local modalHandlers = useModalHandlers(state, dispatch, {
		exporting = exporting,
		uploading = uploading,
		rendering = rendering,
		previewNav = previewNav,
		presets = presets,
		plugin = props.plugin,
		setHelpOpen = setHelpOpen,
		deleteConfirmIndex = deleteConfirmIndex,
		setDeleteConfirmIndex = setDeleteConfirmIndex,
	})

	local deleteConfirmName = ""
	if deleteConfirmIndex then
		local preset = state.presets[deleteConfirmIndex]
		if preset then
			deleteConfirmName = preset.name
		end
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
		hasPrevPreview = if previewNav.previewFromHistory
			then previewNav.prevHistoryIndex ~= nil
			else previewNav.prevRenderedIndex ~= nil,
		hasNextPreview = if previewNav.previewFromHistory
			then previewNav.nextHistoryIndex ~= nil
			else previewNav.nextRenderedIndex ~= nil,
		hideRerender = previewNav.previewFromHistory,
		onClosePreview = modalHandlers.onClosePreview,
		onExportPreview = modalHandlers.onExportPreview,
		onUploadPreview = modalHandlers.onUploadPreview,
		onRerenderPreview = modalHandlers.onRerenderPreview,
		onPrevPreview = modalHandlers.onPrevPreview,
		onNextPreview = modalHandlers.onNextPreview,
		onCloseUploadResults = modalHandlers.onCloseUploadResults,
		onHelpFromUpload = modalHandlers.onHelpFromUpload,
		onCloseDeleteConfirm = modalHandlers.onCloseDeleteConfirm,
		onConfirmDeletePreset = modalHandlers.onConfirmDeletePreset,
		onCloseNameInput = modalHandlers.onCloseNameInput,
		onConfirmNameInput = modalHandlers.onConfirmNameInput,
		onCloseColorPicker = modalHandlers.onCloseColorPicker,
		onCloseHelp = modalHandlers.onCloseHelp,
		toasts = toasts.toasts,
		onRemoveToast = toasts.removeToast,
		onHelpFromToast = modalHandlers.onHelpFromToast,
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
				onTrackball = cameraInput.onTrackball,
				onTranslate = cameraInput.onTranslate,
				onScroll = cameraInput.onScroll,
				onResetCamera = cameraInput.onResetCamera,
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
				onDeletePreset = function(index)
					setDeleteConfirmIndex(index)
				end,
				onRender = rendering.startRenderSelected,
				onRenderAll = rendering.startRenderAll,
				onExport = exporting.doExport,
				onExportSelected = exporting.doExportSelected,
				onUploadAll = uploading.doUploadAll,
				onHelp = function()
					setHelpOpen("General")
				end,
			}),
			modals = e("Folder", {}, modals),
		}),
	})
end

return App

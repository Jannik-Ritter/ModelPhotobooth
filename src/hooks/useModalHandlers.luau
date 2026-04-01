local Store = require(script.Parent.Parent.Store)

type Deps = {
	exporting: { exportPreviewImage: () -> () },
	uploading: { uploadPreviewImage: () -> (), setUploadResults: (any) -> () },
	rendering: { rerenderPreview: () -> () },
	previewNav: {
		previewFromHistory: boolean,
		prevHistoryIndex: number?,
		nextHistoryIndex: number?,
		prevRenderedIndex: number?,
		nextRenderedIndex: number?,
	},
	presets: {
		confirmDeletePreset: (index: number) -> (),
		closeNameInputModal: () -> (),
		confirmNameInput: (name: string) -> (),
	},
	plugin: any,
	setHelpOpen: (tab: any) -> (),
	deleteConfirmIndex: number?,
	setDeleteConfirmIndex: (index: number?) -> (),
}

return function(state: Store.AppState, dispatch: (any) -> (), deps: Deps)
	local function makePreviewNavFn(fromHistory: boolean, backward: boolean)
		return function()
			local idx = if fromHistory
				then (if backward then deps.previewNav.prevHistoryIndex else deps.previewNav.nextHistoryIndex)
				else (if backward then deps.previewNav.prevRenderedIndex else deps.previewNav.nextRenderedIndex)
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

	return {
		onClosePreview = function()
			dispatch({
				type = Store.ACTIONS.SET_PREVIEW_IMAGE,
				image = nil,
				title = nil,
				index = nil,
				historyIndex = nil,
			})
		end,
		onExportPreview = deps.exporting.exportPreviewImage,
		onUploadPreview = deps.uploading.uploadPreviewImage,
		onRerenderPreview = deps.rendering.rerenderPreview,
		onPrevPreview = makePreviewNavFn(deps.previewNav.previewFromHistory, true),
		onNextPreview = makePreviewNavFn(deps.previewNav.previewFromHistory, false),
		onCloseUploadResults = function()
			deps.uploading.setUploadResults(nil)
		end,
		onHelpFromUpload = function()
			deps.uploading.setUploadResults(nil)
			deps.setHelpOpen("Common Issues")
		end,
		onCloseDeleteConfirm = function()
			deps.setDeleteConfirmIndex(nil)
		end,
		onConfirmDeletePreset = function()
			if deps.deleteConfirmIndex then
				deps.presets.confirmDeletePreset(deps.deleteConfirmIndex)
			end
			deps.setDeleteConfirmIndex(nil)
		end,
		onCloseNameInput = deps.presets.closeNameInputModal,
		onConfirmNameInput = deps.presets.confirmNameInput,
		onCloseColorPicker = function()
			dispatch({ type = Store.ACTIONS.SET_COLOR_PICKER_TARGET, value = nil })
		end,
		onCloseHelp = function()
			deps.plugin:SetSetting("hasSeenHelp", true)
			deps.setHelpOpen(nil)
		end,
		onHelpFromToast = function()
			deps.setHelpOpen("Common Issues")
		end,
	}
end

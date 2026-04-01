local Packages = script.Parent.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local Store = require(script.Parent.Parent.Parent.Store)
local Types = require(script.Parent.Parent.Parent.Types)
local ImagePreviewModal = require(script.Parent.ImagePreviewModal)
local ColorPickerModal = require(script.Parent.ColorPickerModal)
local NameInputModal = require(script.Parent.NameInputModal)
local ConfirmModal = require(script.Parent.ConfirmModal)
local HelpShortcutsModal = require(script.Parent.HelpShortcutsModal)
local ProgressModal = require(script.Parent.ProgressModal)
local UploadResultModal = require(script.Parent.UploadResultModal)
local ToastContainer = require(script.Parent.Parent.ToastContainer)
local colorPickerConfig = require(script.Parent.Parent.Parent.utils.colorPickerConfig)

local e = React.createElement

type UploadResult = Types.UploadResult

type Props = {
	state: Store.AppState,
	dispatch: (any) -> (),
	rendering: boolean,
	renderProgress: number,
	renderTotal: number,
	uploading: boolean,
	uploadProgress: number,
	uploadTotal: number,
	uploadResults: { UploadResult }?,
	deleteConfirmIndex: number?,
	deleteConfirmName: string,
	helpOpen: string?,
	hasPrevPreview: boolean,
	hasNextPreview: boolean,
	hideRerender: boolean,
	onClosePreview: () -> (),
	onExportPreview: () -> (),
	onUploadPreview: () -> (),
	onRerenderPreview: () -> (),
	onPrevPreview: (() -> ())?,
	onNextPreview: (() -> ())?,
	onCloseUploadResults: () -> (),
	onHelpFromUpload: () -> (),
	onCloseDeleteConfirm: () -> (),
	onConfirmDeletePreset: () -> (),
	onCloseNameInput: () -> (),
	onConfirmNameInput: (string) -> (),
	onCloseColorPicker: () -> (),
	onCloseHelp: () -> (),
	toasts: { ToastContainer.ToastEntry },
	onRemoveToast: (number) -> (),
	onHelpFromToast: () -> (),
}

local function ModalManager(props: Props)
	local state = props.state

	return {
		progressModal = if state.rendering and state.renderTotal > 0
			then e(ProgressModal, {
				verb = "Rendering",
				progress = state.renderProgress,
				total = state.renderTotal,
			})
			elseif props.uploading and props.uploadTotal > 0 then e(ProgressModal, {
				verb = "Uploading",
				progress = props.uploadProgress,
				total = props.uploadTotal,
			})
			else nil,

		uploadResultModal = if props.uploadResults ~= nil
			then e(UploadResultModal, {
				results = props.uploadResults,
				onClose = props.onCloseUploadResults,
				onHelp = props.onHelpFromUpload,
			})
			else nil,

		imagePreview = if state.previewImage
			then e(ImagePreviewModal, {
				image = state.previewImage,
				title = state.previewTitle or "Preview",
				rendering = state.rendering,
				hasPrev = props.hasPrevPreview,
				hasNext = props.hasNextPreview,
				onClose = props.onClosePreview,
				onExport = props.onExportPreview,
				onUpload = props.onUploadPreview,
				onRerender = props.onRerenderPreview,
				uploading = props.uploading,
				hideRerender = props.hideRerender,
				onPrev = props.onPrevPreview,
				onNext = props.onNextPreview,
			})
			else nil,

		deleteConfirmModal = if props.deleteConfirmIndex ~= nil
			then e(ConfirmModal, {
				title = "Delete Preset",
				message = `Delete "{props.deleteConfirmName}"?`,
				confirmLabel = "Delete",
				onConfirm = props.onConfirmDeletePreset,
				onClose = props.onCloseDeleteConfirm,
			})
			else nil,

		nameInputModal = if state.nameInputModal ~= nil
			then e(NameInputModal, {
				mode = state.nameInputModal.mode,
				initialName = state.nameInputModal.initialName,
				onConfirm = props.onConfirmNameInput,
				onClose = props.onCloseNameInput,
			})
			else nil,

		colorPickerModal = if state.colorPickerTarget ~= nil
			then (function()
				local config = colorPickerConfig[state.colorPickerTarget]
				if not config then return nil end
				return e(ColorPickerModal, {
					title = config.title,
					color = config.getColor(state),
					onColorChanged = function(c)
						props.dispatch(config.makeAction(c))
					end,
					onClose = props.onCloseColorPicker,
				})
			end)()
			else nil,

		helpShortcutsModal = if props.helpOpen
			then e(HelpShortcutsModal, {
				initialTab = props.helpOpen,
				onClose = props.onCloseHelp,
			})
			else nil,

		toastContainer = e(ToastContainer, {
			toasts = props.toasts,
			onRemove = props.onRemoveToast,
			onHelp = props.onHelpFromToast,
		}),
	}
end

return ModalManager

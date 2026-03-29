local Store = {}

Store.ACTIONS = {
	SET_CAMERA = "SET_CAMERA",
	SET_YAW = "SET_YAW",
	SET_PITCH = "SET_PITCH",
	SET_ROLL = "SET_ROLL",
	SET_FOV = "SET_FOV",
	SET_OUTLINE = "SET_OUTLINE",
	SET_DROP_SHADOW = "SET_DROP_SHADOW",
	SET_INNER_SHADOW = "SET_INNER_SHADOW",
	SET_BG_MODE = "SET_BG_MODE",
	SET_BG_COLOR = "SET_BG_COLOR",
	SET_EXPORT_SIZE = "SET_EXPORT_SIZE",
	SET_MODELS = "SET_MODELS",
	SET_RENDER_STATUS = "SET_RENDER_STATUS",
	SET_RENDERING = "SET_RENDERING",
	SET_SELECTION = "SET_SELECTION",
	TOGGLE_SECTION = "TOGGLE_SECTION",
	SET_COLOR_PICKER_TARGET = "SET_COLOR_PICKER_TARGET",
	SET_PREVIEW_IMAGE = "SET_PREVIEW_IMAGE",
	SET_PRESETS = "SET_PRESETS",
	SET_NAME_INPUT_MODAL = "SET_NAME_INPUT_MODAL",
	APPLY_PRESET = "APPLY_PRESET",
	SET_CAMERA_DISTANCE = "SET_CAMERA_DISTANCE",
	SET_OUTER_GLOW = "SET_OUTER_GLOW",
	SET_CHROMATIC_ABERRATION = "SET_CHROMATIC_ABERRATION",
}

export type RenderStatus = "idle" | "pending" | "ok" | "fail"

export type ModelEntry = {
	instance: Instance,
	status: RenderStatus,
	image: EditableImage?,
	isExported: boolean,
}

export type OutlineState = {
	enabled: boolean,
	color: Color3,
	thickness: number,
}

export type EffectState = {
	enabled: boolean,
	color: Color3,
	opacity: number,
	distance: number,
	blur: number,
	angle: number,
}

export type InnerShadowState = {
	enabled: boolean,
	color: Color3,
	opacity: number,
	distance: number,
	blur: number,
	angle: number,
}

export type OuterGlowState = {
	enabled: boolean,
	color: Color3,
	size: number,
	opacity: number,
	blur: number,
}

export type ChromaticAberrationState = {
	enabled: boolean,
	distance: number,
	opacity: number,
	angle: number,
}

export type PresetEntry = {
	name: string,
	yaw: number,
	pitch: number,
	roll: number,
	fov: number,
	cameraDistance: number,
	bgMode: string,
	bgColor: Color3,
	exportSize: number,
	outline: OutlineState,
	dropShadow: EffectState,
	innerShadow: InnerShadowState,
	outerGlow: OuterGlowState,
	chromaticAberration: ChromaticAberrationState,
}

export type NameInputModalState = {
	mode: "save" | "rename",
	targetIndex: number?,
	initialName: string?,
}

export type AppState = {
	yaw: number,
	pitch: number,
	roll: number,
	fov: number,
	cameraDistance: number,
	outline: OutlineState,
	dropShadow: EffectState,
	innerShadow: InnerShadowState,
	outerGlow: OuterGlowState,
	chromaticAberration: ChromaticAberrationState,
	bgMode: string,
	bgColor: Color3,
	exportSize: number,
	models: { ModelEntry },
	rendering: boolean,
	renderProgress: number,
	renderTotal: number,
	selectedModelIndices: { number },
	collapsedSections: { [string]: boolean },
	colorPickerTarget: string?,
	previewImage: EditableImage?,
	previewTitle: string?,
	previewModelIndex: number?,
	presets: { PresetEntry },
	nameInputModal: NameInputModalState?,
}

Store.DEFAULT_STATE = {
	yaw = 180 + 45,
	pitch = 25,
	roll = 0,
	fov = 70,
	cameraDistance = 1,
	outline = { enabled = false, color = Color3.new(0, 0, 0), thickness = 3 },
	dropShadow = { enabled = false, color = Color3.new(0, 0, 0), opacity = 75, distance = 4, blur = 6, angle = 45 },
	innerShadow = { enabled = false, color = Color3.new(0, 0, 0), opacity = 75, distance = 4, blur = 6, angle = 225 },
	outerGlow = { enabled = false, color = Color3.new(1, 1, 1), size = 10, opacity = 75, blur = 6 },
	chromaticAberration = { enabled = false, distance = 4, opacity = 100, angle = 45 },
	bgMode = "transparent",
	bgColor = Color3.new(1, 1, 1),
	exportSize = 0,
	models = {},
	rendering = false,
	renderProgress = 0,
	renderTotal = 0,
	selectedModelIndices = {},
	collapsedSections = {},
	colorPickerTarget = nil,
	previewImage = nil,
	previewTitle = nil,
	previewModelIndex = nil,
	presets = {},
	nameInputModal = nil,
}

Store.PRESETS = {
	Front = { yaw = 180, pitch = 10, fov = 70 },
	Side = { yaw = -90, pitch = 10, fov = 70 },
	Back = { yaw = 0, pitch = 10, fov = 70 },
	Top = { yaw = 0, pitch = 90, fov = 70 },
	Iso = { yaw = 18 + 45 + 180, pitch = 35, fov = 1 },
	Angled = { yaw = 315 - 90, pitch = 20, fov = 70 },
}

local actions = script.Parent.actions
local A = Store.ACTIONS

local handlers = {
	[A.SET_CAMERA] = require(actions.setCamera),
	[A.SET_YAW] = require(actions.setYaw),
	[A.SET_PITCH] = require(actions.setPitch),
	[A.SET_ROLL] = require(actions.setRoll),
	[A.SET_FOV] = require(actions.setFov),
	[A.SET_OUTLINE] = require(actions.setOutline),
	[A.SET_DROP_SHADOW] = require(actions.setDropShadow),
	[A.SET_INNER_SHADOW] = require(actions.setInnerShadow),
	[A.SET_BG_MODE] = require(actions.setBgMode),
	[A.SET_BG_COLOR] = require(actions.setBgColor),
	[A.SET_EXPORT_SIZE] = require(actions.setExportSize),
	[A.SET_MODELS] = require(actions.setModels),
	[A.SET_RENDER_STATUS] = require(actions.setRenderStatus),
	[A.SET_RENDERING] = require(actions.setRendering),
	[A.SET_SELECTION] = require(actions.setSelection),
	[A.TOGGLE_SECTION] = require(actions.toggleSection),
	[A.SET_COLOR_PICKER_TARGET] = require(actions.setColorPickerTarget),
	[A.SET_PREVIEW_IMAGE] = require(actions.setPreviewImage),
	[A.SET_PRESETS] = require(actions.setPresets),
	[A.SET_NAME_INPUT_MODAL] = require(actions.setNameInputModal),
	[A.APPLY_PRESET] = require(actions.applyPreset),
	[A.SET_CAMERA_DISTANCE] = require(actions.setCameraDistance),
	[A.SET_OUTER_GLOW] = require(actions.setOuterGlow),
	[A.SET_CHROMATIC_ABERRATION] = require(actions.setChromaticAberration),
}

function Store.reducer(state: AppState, action): AppState
	local handler = handlers[action.type]
	if handler then
		return handler(state, action)
	end
	return state
end

return Store

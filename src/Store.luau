local Store = {}

Store.ACTIONS = {
	SET_CAMERA = "SET_CAMERA",
	SET_YAW = "SET_YAW",
	SET_PITCH = "SET_PITCH",
	SET_FOV = "SET_FOV",
	SET_OUTLINE = "SET_OUTLINE",
	SET_DROP_SHADOW = "SET_DROP_SHADOW",
	SET_INNER_SHADOW = "SET_INNER_SHADOW",
	SET_BG_MODE = "SET_BG_MODE",
	SET_BG_COLOR = "SET_BG_COLOR",
	SET_EXPORT_SIZE = "SET_EXPORT_SIZE",
	SET_MODELS = "SET_MODELS",
	SET_CAPTURE_STATUS = "SET_CAPTURE_STATUS",
	SET_CAPTURING = "SET_CAPTURING",
	SET_SELECTION = "SET_SELECTION",
	TOGGLE_SECTION = "TOGGLE_SECTION",
	SET_COLOR_PICKER_TARGET = "SET_COLOR_PICKER_TARGET",
	SET_PREVIEW_IMAGE = "SET_PREVIEW_IMAGE",
}

export type CaptureStatus = "idle" | "pending" | "ok" | "fail"

export type ModelEntry = {
	instance: Instance,
	status: CaptureStatus,
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

export type AppState = {
	yaw: number,
	pitch: number,
	fov: number,
	outline: OutlineState,
	dropShadow: EffectState,
	innerShadow: InnerShadowState,
	bgMode: string,
	bgColor: Color3,
	exportSize: number,
	models: { ModelEntry },
	capturing: boolean,
	captureProgress: number,
	captureTotal: number,
	selectedModelIndices: { number },
	collapsedSections: { [string]: boolean },
	colorPickerTarget: string?,
	previewImage: EditableImage?,
	previewTitle: string?,
	previewModelIndex: number?,
}

Store.DEFAULT_STATE = {
	yaw = 180 + 45,
	pitch = 25,
	fov = 70,
	outline = { enabled = false, color = Color3.new(0, 0, 0), thickness = 3 },
	dropShadow = { enabled = false, color = Color3.new(0, 0, 0), opacity = 75, distance = 4, blur = 6, angle = 45 },
	innerShadow = { enabled = false, color = Color3.new(0, 0, 0), opacity = 75, distance = 4, blur = 6, angle = 225 },
	bgMode = "transparent",
	bgColor = Color3.new(1, 1, 1),
	exportSize = 0,
	models = {},
	capturing = false,
	captureProgress = 0,
	captureTotal = 0,
	selectedModelIndices = {},
	collapsedSections = {},
	colorPickerTarget = nil,
	previewImage = nil,
	previewTitle = nil,
	previewModelIndex = nil,
}

Store.PRESETS = {
	Front = { yaw = 180, pitch = 10, fov = 70 },
	Side = { yaw = 18 + 90, pitch = 10, fov = 70 },
	Iso = { yaw = 18 + 45, pitch = 35, fov = 1 },
	["3/4"] = { yaw = 315, pitch = 20, fov = 70 },
}

local actions = script.Parent.actions
local A = Store.ACTIONS

local handlers = {
	[A.SET_CAMERA] = require(actions.setCamera),
	[A.SET_YAW] = require(actions.setYaw),
	[A.SET_PITCH] = require(actions.setPitch),
	[A.SET_FOV] = require(actions.setFov),
	[A.SET_OUTLINE] = require(actions.setOutline),
	[A.SET_DROP_SHADOW] = require(actions.setDropShadow),
	[A.SET_INNER_SHADOW] = require(actions.setInnerShadow),
	[A.SET_BG_MODE] = require(actions.setBgMode),
	[A.SET_BG_COLOR] = require(actions.setBgColor),
	[A.SET_EXPORT_SIZE] = require(actions.setExportSize),
	[A.SET_MODELS] = require(actions.setModels),
	[A.SET_CAPTURE_STATUS] = require(actions.setCaptureStatus),
	[A.SET_CAPTURING] = require(actions.setCapturing),
	[A.SET_SELECTION] = require(actions.setSelection),
	[A.TOGGLE_SECTION] = require(actions.toggleSection),
	[A.SET_COLOR_PICKER_TARGET] = require(actions.setColorPickerTarget),
	[A.SET_PREVIEW_IMAGE] = require(actions.setPreviewImage),
}

function Store.reducer(state: AppState, action): AppState
	local handler = handlers[action.type]
	if handler then
		return handler(state, action)
	end
	return state
end

return Store

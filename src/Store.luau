local Store = {}

Store.ACTIONS = {
	SET_CAMERA = "SET_CAMERA",
	SET_YAW = "SET_YAW",
	SET_PITCH = "SET_PITCH",
	SET_ROLL = "SET_ROLL",
	SET_FOV = "SET_FOV",
	SET_CAMERA_OFFSET = "SET_CAMERA_OFFSET",
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
	SET_LIGHTING = "SET_LIGHTING",
	SET_ANIMATIONS = "SET_ANIMATIONS",
	SET_ACTIVE_ANIMATION = "SET_ACTIVE_ANIMATION",
	SET_ANIMATION_PLAYING = "SET_ANIMATION_PLAYING",
	SET_ANIMATION_TIME = "SET_ANIMATION_TIME",
	SET_ANIMATION_LENGTH = "SET_ANIMATION_LENGTH",
	SET_RENDER_HISTORY_ENTRY = "SET_RENDER_HISTORY_ENTRY",
}

local Types = require(script.Parent.Types)
local Constants = require(script.Parent.Constants)

type AppState = Types.AppState

Store.DEFAULT_STATE = {
	yaw = 180 + 45,
	pitch = 25,
	roll = 0,
	fov = 70,
	cameraDistance = 1,
	cameraOffsetX = 0,
	cameraOffsetY = 0,
	cameraOffsetZ = 0,
	outline = { enabled = false, color = Color3.new(0, 0, 0), thickness = 3 },
	dropShadow = { enabled = false, color = Color3.new(0, 0, 0), opacity = 75, distance = 4, blur = 6, angle = 45 },
	innerShadow = { enabled = false, color = Color3.new(0, 0, 0), opacity = 75, distance = 4, blur = 6, angle = 225 },
	outerGlow = { enabled = false, color = Color3.new(1, 1, 1), size = 10, opacity = 75, blur = 6 },
	chromaticAberration = { enabled = false, distance = 4, opacity = 100, angle = 45 },
	lighting = Constants.DEFAULT_LIGHTING,
	bgMode = "transparent",
	bgColor = Color3.new(1, 1, 1),
	exportSize = 0,
	models = {},
	renderHistory = {},
	rendering = false,
	renderProgress = 0,
	renderTotal = 0,
	selectedModelIndices = {},
	collapsedSections = {},
	colorPickerTarget = nil,
	previewImage = nil,
	previewTitle = nil,
	previewModelIndex = nil,
	previewHistoryIndex = nil,
	presets = {},
	nameInputModal = nil,
	animations = {},
	activeAnimationIndex = nil,
	animationPlaying = false,
	animationTimePosition = 0,
	animationLength = 0,
}

Store.PRESETS = {
	Front = { yaw = 180, pitch = 10, fov = 70 },
	Side = { yaw = -90, pitch = 10, fov = 70 },
	Back = { yaw = 0, pitch = 10, fov = 70 },
	Top = { yaw = 0, pitch = Constants.CAMERA_PITCH_MAX, fov = 70 },
	Iso = { yaw = 18 + 45 + 180, pitch = 35, fov = 1 },
	Angled = { yaw = 315 - 90, pitch = 20, fov = 70 },
}

local actions = script.Parent.actions
local A = Store.ACTIONS

local createSetter = require(script.Parent.utils.createSetter)
local mergeNestedSlice = require(script.Parent.utils.mergeNestedSlice)

local handlers = {
	[A.SET_CAMERA] = require(actions.setCamera),
	[A.SET_YAW] = createSetter("yaw"),
	[A.SET_PITCH] = createSetter("pitch"),
	[A.SET_ROLL] = createSetter("roll"),
	[A.SET_FOV] = createSetter("fov"),
	[A.SET_OUTLINE] = mergeNestedSlice("outline"),
	[A.SET_DROP_SHADOW] = mergeNestedSlice("dropShadow"),
	[A.SET_INNER_SHADOW] = mergeNestedSlice("innerShadow"),
	[A.SET_BG_MODE] = createSetter("bgMode"),
	[A.SET_BG_COLOR] = createSetter("bgColor"),
	[A.SET_EXPORT_SIZE] = createSetter("exportSize"),
	[A.SET_MODELS] = createSetter("models"),
	[A.SET_RENDER_STATUS] = require(actions.setRenderStatus),
	[A.SET_RENDERING] = require(actions.setRendering),
	[A.SET_SELECTION] = createSetter("selectedModelIndices"),
	[A.TOGGLE_SECTION] = require(actions.toggleSection),
	[A.SET_COLOR_PICKER_TARGET] = require(actions.setColorPickerTarget),
	[A.SET_PREVIEW_IMAGE] = require(actions.setPreviewImage),
	[A.SET_PRESETS] = createSetter("presets"),
	[A.SET_NAME_INPUT_MODAL] = require(actions.setNameInputModal),
	[A.APPLY_PRESET] = require(actions.applyPreset),
	[A.SET_CAMERA_DISTANCE] = createSetter("cameraDistance"),
	[A.SET_CAMERA_OFFSET] = require(actions.setCameraOffset),
	[A.SET_OUTER_GLOW] = mergeNestedSlice("outerGlow"),
	[A.SET_CHROMATIC_ABERRATION] = mergeNestedSlice("chromaticAberration"),
	[A.SET_LIGHTING] = mergeNestedSlice("lighting"),
	[A.SET_ANIMATIONS] = require(actions.setAnimations),
	[A.SET_ACTIVE_ANIMATION] = require(actions.setActiveAnimation),
	[A.SET_ANIMATION_PLAYING] = createSetter("animationPlaying"),
	[A.SET_ANIMATION_TIME] = createSetter("animationTimePosition"),
	[A.SET_ANIMATION_LENGTH] = createSetter("animationLength"),
	[A.SET_RENDER_HISTORY_ENTRY] = require(actions.setRenderHistoryEntry),
}

-- Startup check: every action constant must have a registered handler.
for name, key in pairs(A) do
	assert(handlers[key] ~= nil, "Store: no handler registered for action " .. name)
end

function Store.reducer(state: AppState, action): AppState
	local handler = handlers[action.type]
	if handler then
		return handler(state, action)
	end
	return state
end

return Store

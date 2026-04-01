-- Lookup table replacing the 60-line if/else chain for color picker modal config.
local Store = require(script.Parent.Parent.Store)

local A = Store.ACTIONS

type PickerConfig = {
	title: string,
	getColor: (Store.AppState) -> Color3,
	makeAction: (Color3) -> { [string]: any },
}

local CONFIG: { [string]: PickerConfig } = {
	outline = {
		title = "Outline Color",
		getColor = function(state) return state.outline.color end,
		makeAction = function(c) return { type = A.SET_OUTLINE, value = { color = c } } end,
	},
	shadow = {
		title = "Shadow Color",
		getColor = function(state) return state.dropShadow.color end,
		makeAction = function(c) return { type = A.SET_DROP_SHADOW, value = { color = c } } end,
	},
	inner = {
		title = "Inner Shadow Color",
		getColor = function(state) return state.innerShadow.color end,
		makeAction = function(c) return { type = A.SET_INNER_SHADOW, value = { color = c } } end,
	},
	background = {
		title = "Background Color",
		getColor = function(state) return state.bgColor end,
		makeAction = function(c) return { type = A.SET_BG_COLOR, value = c } end,
	},
	lightColor = {
		title = "Light Color",
		getColor = function(state) return state.lighting.lightColor end,
		makeAction = function(c) return { type = A.SET_LIGHTING, value = { lightColor = c } } end,
	},
	ambient = {
		title = "Ambient Color",
		getColor = function(state) return state.lighting.ambient end,
		makeAction = function(c) return { type = A.SET_LIGHTING, value = { ambient = c } } end,
	},
	outerGlow = {
		title = "Outer Glow Color",
		getColor = function(state) return state.outerGlow.color end,
		makeAction = function(c) return { type = A.SET_OUTER_GLOW, value = { color = c } } end,
	},
}

return CONFIG

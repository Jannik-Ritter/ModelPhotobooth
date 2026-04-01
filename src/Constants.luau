-- Shared layout tokens, camera limits, and export/capture sizing for the plugin.
return {
	-- CollectionService tag applied to all exported MeshPart icons
	MPB_TAG = "_MPBIcon",

	-- Default lighting preset (used by Store.DEFAULT_STATE and preset deserialization)
	DEFAULT_LIGHTING = {
		lightColor = Color3.new(1, 1, 1),
		ambient = Color3.fromRGB(160, 160, 160),
		lightDirectionX = -1,
		lightDirectionY = -2,
		lightDirectionZ = -1,
	},

	-- UI chrome (modals, toolbar, icons)
	MODAL_TITLE_BAR_HEIGHT = 32,
	MODAL_DEFAULT_WIDTH = 360,
	TOOLBAR_ICON_GLYPH = Vector2.new(16, 16),

	-- Camera (sidebar, viewport interaction)
	FOV_MIN = 1,
	FOV_MAX = 120,
	FOV_SCROLL_STEP = 3,
	CAMERA_DISTANCE_MIN = 0.1,
	CAMERA_DISTANCE_MAX = 3,
	CAMERA_DISTANCE_SCROLL_STEP = 0.1,
	CAMERA_OFFSET_MIN = -500,
	CAMERA_OFFSET_MAX = 500,
	CAMERA_OFFSET_STEP = 0.1,
	LIGHT_DIRECTION_MIN = -999,
	LIGHT_DIRECTION_MAX = 999,
	LIGHT_DIRECTION_STEP = 0.1,

	-- Export / capture (UI, render pipeline, help copy)
	CAPTURE_MAX_DIMENSION = 1020,
	HELP_MIN_VIEWPORT_PX = 1024,
	EXPORT_SIZE_PRESETS = {
		{ label = "Native", value = 0 },
		{ label = "1024", value = 1024 },
		{ label = "512", value = 512 },
		{ label = "256", value = 256 },
		{ label = "128", value = 128 },
	},
}

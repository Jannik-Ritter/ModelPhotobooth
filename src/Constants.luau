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
	MODAL_FOOTER_HEIGHT = 40,
	TOOLBAR_ICON_GLYPH = Vector2.new(16, 16),

	-- Layout / spacing
	LIST_PADDING = UDim.new(0, 6),
	LIST_PADDING_SMALL = UDim.new(0, 4),
	GROUP_PADDING = UDim.new(0, 2),
	PADDING_8 = 8,
	HEADER_HEIGHT = 26,
	ROW_HEIGHT = 22,
	BUTTON_HEIGHT = 24,
	CORNER_RADIUS_4 = 4,
	CORNER_RADIUS_3 = 3,
	STROKE_THIN = 1,
	STROKE_ACTIVE = 2,
	TEXT_SIZE_HEADING = 18,
	TEXT_SIZE_BODY = 16,
	TEXT_SIZE_SMALL = 13,

	-- Strip chrome
	STRIP_PADDING_V = 9,
	STRIP_DEFAULT_HEIGHT = 80,
	THUMB_MIN_SIZE = 20,
	THUMB_NAME_ROW_HEIGHT = 16,

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
	ROLL_MIN = -180,
	ROLL_MAX = 180,
	LIGHT_DIRECTION_MIN = -999,
	LIGHT_DIRECTION_MAX = 999,
	LIGHT_DIRECTION_STEP = 0.1,

	-- Viewport / bounds
	BOUNDS_PADDING_FACTOR = 1.18,
	DEFAULT_BOUNDS_SIZE = Vector3.new(4, 4, 4),
	ROTATION_SENSITIVITY = 0.5,

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
	EXPORT_FOLDER_NAME = "PhotoboothExports",
	EXPORT_MESH_SIZE = Vector3.new(4, 4, 0.05),
	EXPORT_SPACING = 5,

	-- Post-processing defaults
	ALPHA_THRESHOLD = 128,
	MIN_VISIBLE_ALPHA = 2,
	DEFAULT_DROP_SHADOW_ANGLE = 45,
	DEFAULT_INNER_SHADOW_ANGLE = 225,

	-- Polling / async
	POLL_INTERVAL = 0.05,
	MAX_POLL_ATTEMPTS = 100,
	FRAME_DT = 1 / 60,
	SCREENSHOT_TIMEOUT = 6,

	-- Misc
	ZINDEX_OVERLAY = 9999,
	POSE_STEP_COUNT = 3,
	MAX_RENDER_HISTORY = 25,
}

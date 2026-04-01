-- Serializes/deserializes preset lists for plugin:SetSetting / plugin:GetSetting.
-- Color3 userdata cannot be stored directly, so each Color3 is converted to
-- a plain {r, g, b} table and back.

local Constants = require(script.Parent.Parent.Constants)

local function serializeColor(c: Color3): { r: number, g: number, b: number }
	return { r = c.R, g = c.G, b = c.B }
end

local function deserializeColor(t): Color3
	return Color3.new(t.r, t.g, t.b)
end

-- Copies `plainFields` verbatim and applies serializeColor to `colorFields`.
-- `defaults` fills in any nil plain fields (for backwards-compatible deserialization).
local function serializeFields(src, plainFields: { string }, colorFields: { string }): { [string]: any }
	local result = {}
	for _, field in ipairs(plainFields) do
		result[field] = src[field]
	end
	for _, field in ipairs(colorFields) do
		result[field] = serializeColor(src[field])
	end
	return result
end

local function deserializeFields(
	t,
	plainFields: { string },
	colorFields: { string },
	defaults: { [string]: any }?
): { [string]: any }
	local result = {}
	local defs = defaults or {}
	for _, field in ipairs(plainFields) do
		result[field] = if t[field] ~= nil then t[field] else defs[field]
	end
	for _, field in ipairs(colorFields) do
		result[field] = deserializeColor(t[field])
	end
	return result
end

local EFFECT_PLAIN = { "enabled", "opacity", "distance", "blur", "angle" }
local EFFECT_COLOR = { "color" }
local function serializeEffect(e)
	return serializeFields(e, EFFECT_PLAIN, EFFECT_COLOR)
end
local function deserializeEffect(t)
	return deserializeFields(t, EFFECT_PLAIN, EFFECT_COLOR)
end

local OUTER_GLOW_PLAIN = { "enabled", "size", "opacity", "blur" }
local OUTER_GLOW_COLOR = { "color" }
local OUTER_GLOW_DEFAULTS = { size = 10 }
local function serializeOuterGlow(g)
	return serializeFields(g, OUTER_GLOW_PLAIN, OUTER_GLOW_COLOR)
end
local function deserializeOuterGlow(t)
	return deserializeFields(t, OUTER_GLOW_PLAIN, OUTER_GLOW_COLOR, OUTER_GLOW_DEFAULTS)
end

local OUTLINE_PLAIN = { "enabled", "thickness" }
local OUTLINE_COLOR = { "color" }
local function serializeOutline(o)
	return serializeFields(o, OUTLINE_PLAIN, OUTLINE_COLOR)
end
local function deserializeOutline(t)
	return deserializeFields(t, OUTLINE_PLAIN, OUTLINE_COLOR)
end

local DEFAULT_LIGHTING = Constants.DEFAULT_LIGHTING
local LIGHTING_PLAIN = { "lightDirectionX", "lightDirectionY", "lightDirectionZ" }
local LIGHTING_COLOR = { "lightColor", "ambient" }
local LIGHTING_DEFAULTS = { lightDirectionX = -1, lightDirectionY = -2, lightDirectionZ = -1 }

local function serializeLighting(l)
	return serializeFields(if l then l else DEFAULT_LIGHTING, LIGHTING_PLAIN, LIGHTING_COLOR)
end
local function deserializeLighting(t)
	return deserializeFields(t, LIGHTING_PLAIN, LIGHTING_COLOR, LIGHTING_DEFAULTS)
end

local Serialization = {}

function Serialization.serialize(presets: { any }): { any }
	local result = {}
	for _, preset in ipairs(presets) do
		table.insert(result, {
			name = preset.name,
			yaw = preset.yaw,
			pitch = preset.pitch,
			roll = preset.roll,
			fov = preset.fov,
			cameraDistance = preset.cameraDistance,
			cameraOffsetX = preset.cameraOffsetX or 0,
			cameraOffsetY = preset.cameraOffsetY or 0,
			cameraOffsetZ = preset.cameraOffsetZ or 0,
			bgMode = preset.bgMode,
			bgColor = serializeColor(preset.bgColor),
			exportSize = preset.exportSize,
			outline = serializeOutline(preset.outline),
			dropShadow = serializeEffect(preset.dropShadow),
			innerShadow = serializeEffect(preset.innerShadow),
			outerGlow = serializeOuterGlow(preset.outerGlow),
			chromaticAberration = {
				enabled = preset.chromaticAberration.enabled,
				distance = preset.chromaticAberration.distance,
				opacity = preset.chromaticAberration.opacity,
				angle = preset.chromaticAberration.angle,
			},
			lighting = serializeLighting(preset.lighting),
		})
	end
	return result
end

function Serialization.deserialize(raw: { any }): { any }
	local result = {}
	for _, t in ipairs(raw) do
		table.insert(result, {
			name = t.name,
			yaw = t.yaw,
			pitch = t.pitch,
			roll = t.roll or 0,
			fov = t.fov,
			cameraDistance = t.cameraDistance or 1,
			cameraOffsetX = t.cameraOffsetX or 0,
			cameraOffsetY = t.cameraOffsetY or 0,
			cameraOffsetZ = t.cameraOffsetZ or 0,
			bgMode = t.bgMode,
			bgColor = deserializeColor(t.bgColor),
			exportSize = t.exportSize,
			outline = deserializeOutline(t.outline),
			dropShadow = deserializeEffect(t.dropShadow),
			innerShadow = deserializeEffect(t.innerShadow),
			outerGlow = if t.outerGlow
				then deserializeOuterGlow(t.outerGlow)
				else { enabled = false, color = Color3.new(1, 1, 1), size = 10, opacity = 75, blur = 6 },
			chromaticAberration = if t.chromaticAberration
				then {
					enabled = t.chromaticAberration.enabled,
					distance = t.chromaticAberration.distance or t.chromaticAberration.amount or 4,
					opacity = t.chromaticAberration.opacity or 100,
					angle = t.chromaticAberration.angle or 45,
				}
				else { enabled = false, distance = 4, opacity = 100, angle = 45 },
			lighting = if t.lighting then deserializeLighting(t.lighting) else DEFAULT_LIGHTING,
		})
	end
	return result
end

return Serialization

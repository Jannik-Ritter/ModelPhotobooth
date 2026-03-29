-- Serializes/deserializes preset lists for plugin:SetSetting / plugin:GetSetting.
-- Color3 userdata cannot be stored directly, so each Color3 is converted to
-- a plain {r, g, b} table and back.

local function serializeColor(c: Color3): { r: number, g: number, b: number }
	return { r = c.R, g = c.G, b = c.B }
end

local function deserializeColor(t): Color3
	return Color3.new(t.r, t.g, t.b)
end

local function serializeEffect(e)
	return {
		enabled = e.enabled,
		color = serializeColor(e.color),
		opacity = e.opacity,
		distance = e.distance,
		blur = e.blur,
		angle = e.angle,
	}
end

local function deserializeEffect(t)
	return {
		enabled = t.enabled,
		color = deserializeColor(t.color),
		opacity = t.opacity,
		distance = t.distance,
		blur = t.blur,
		angle = t.angle,
	}
end

local function serializeOutline(o)
	return {
		enabled = o.enabled,
		color = serializeColor(o.color),
		thickness = o.thickness,
	}
end

local function deserializeOutline(t)
	return {
		enabled = t.enabled,
		color = deserializeColor(t.color),
		thickness = t.thickness,
	}
end

local Serialization = {}

function Serialization.serialize(presets: { any }): { any }
	local result = {}
	for _, preset in ipairs(presets) do
		table.insert(result, {
			name = preset.name,
			yaw = preset.yaw,
			pitch = preset.pitch,
			fov = preset.fov,
			cameraDistance = preset.cameraDistance,
			bgMode = preset.bgMode,
			bgColor = serializeColor(preset.bgColor),
			exportSize = preset.exportSize,
			outline = serializeOutline(preset.outline),
			dropShadow = serializeEffect(preset.dropShadow),
			innerShadow = serializeEffect(preset.innerShadow),
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
			fov = t.fov,
			cameraDistance = t.cameraDistance or 1,
			bgMode = t.bgMode,
			bgColor = deserializeColor(t.bgColor),
			exportSize = t.exportSize,
			outline = deserializeOutline(t.outline),
			dropShadow = deserializeEffect(t.dropShadow),
			innerShadow = deserializeEffect(t.innerShadow),
		})
	end
	return result
end

return Serialization

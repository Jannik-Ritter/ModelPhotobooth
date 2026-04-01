local getCF = require(script.Parent.getCF)
local Types = require(script.Parent.Parent.Types)

export type CameraParams = Types.CameraParams
export type BoundsSnapshot = Types.BoundsSnapshot

local function toOffsetVector(params: Types.CameraParams): Vector3
	return Vector3.new(params.offsetX, params.offsetY, params.offsetZ)
end

-- Applies camera settings to a Camera instance for the given target.
-- Optionally uses cached bounds for stable framing.
local function applyCamera(
	camera: Camera,
	target: Instance,
	params: Types.CameraParams,
	bounds: Types.BoundsSnapshot?
)
	camera.FieldOfView = math.max(params.fov, 1)
	camera.CFrame = getCF(
		target,
		params.yaw,
		params.pitch,
		params.fov,
		params.cameraDistance,
		params.roll,
		toOffsetVector(params),
		if bounds then bounds.cf else nil,
		if bounds then bounds.size else nil
	)
end

return applyCamera

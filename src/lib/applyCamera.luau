local getCF = require(script.Parent.getCF)

export type CameraParams = {
	yaw: number,
	pitch: number,
	roll: number,
	fov: number,
	cameraDistance: number,
	offsetX: number,
	offsetY: number,
	offsetZ: number,
}

export type BoundsSnapshot = {
	cf: CFrame,
	size: Vector3,
}

local function toOffsetVector(params: CameraParams): Vector3
	return Vector3.new(params.offsetX, params.offsetY, params.offsetZ)
end

-- Applies camera settings to a Camera instance for the given target.
-- Optionally uses cached bounds for stable framing.
local function applyCamera(
	camera: Camera,
	target: Instance,
	params: CameraParams,
	bounds: BoundsSnapshot?
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

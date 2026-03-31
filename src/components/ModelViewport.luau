local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)

local Store = require(script.Parent.Parent.Store)
local applyCamera = require(script.Parent.Parent.lib.applyCamera)
local getBoundsSnapshot = require(script.Parent.Parent.lib.viewportBounds)

local e = React.createElement

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

export type ViewportRefs = {
	viewportFrame: { current: ViewportFrame? },
	camera: { current: Camera? },
	clone: { current: Instance? },
	bounds: { current: { cf: CFrame, size: Vector3 }? },
}

export type Props = {
	instance: Instance,
	lighting: Store.LightingState,
	camera: CameraParams,
	Size: UDim2,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	BackgroundColor3: Color3,
	BorderSizePixel: number?,
	ZIndex: number?,
	children: { [string]: any }?,
	-- Optional refs for parent access (e.g., for animation)
	refs: ViewportRefs?,
}

local function ModelViewport(props: Props)
	local vpRef = React.useRef(nil :: ViewportFrame?)
	local camRef = React.useRef(nil :: Camera?)
	local cloneRef = React.useRef(nil :: Instance?)
	local boundsRef = React.useRef(nil :: { cf: CFrame, size: Vector3 }?)

	local camera = props.camera

	-- Allow parent to provide external refs
	if props.refs then
		vpRef = props.refs.viewportFrame
		camRef = props.refs.camera
		cloneRef = props.refs.clone
		boundsRef = props.refs.bounds
	end

	-- Setup: Camera + WorldModel + Clone
	React.useEffect(
		function()
			local vp = vpRef.current
			if not vp then
				return
			end

			local cam = Instance.new("Camera")
			cam.Parent = vp
			vp.CurrentCamera = cam
			camRef.current = cam

			local worldModel = Instance.new("WorldModel")
			worldModel.Parent = vp

			local clone
			local ok = pcall(function()
				clone = props.instance:Clone()
				clone.Parent = worldModel
			end)
			if not ok or not clone then
				cam:Destroy()
				worldModel:Destroy()
				camRef.current = nil
				return
			end

			cloneRef.current = clone
			boundsRef.current = getBoundsSnapshot(clone)

			return function()
				if camRef.current == cam then
					camRef.current = nil
				end
				if vp.CurrentCamera == cam then
					vp.CurrentCamera = nil
				end
				if cloneRef.current == clone then
					cloneRef.current = nil
				end
				boundsRef.current = nil
				cam:Destroy()
				worldModel:Destroy()
			end
		end,
		{ props.instance } :: { any }
	)

	-- Update camera when params or instance change
	React.useEffect(
		function()
			local cam = camRef.current
			local clone = cloneRef.current
			if not cam or not clone then
				return
			end

			applyCamera(cam, clone, camera, boundsRef.current)
		end,
		{
			props.instance,
			camera.yaw,
			camera.pitch,
			camera.fov,
			camera.cameraDistance,
			camera.roll,
			camera.offsetX,
			camera.offsetY,
			camera.offsetZ,
		} :: { any }
	)

	local lighting = props.lighting
	return e("ViewportFrame", {
		ref = vpRef,
		Size = props.Size,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		BackgroundColor3 = props.BackgroundColor3,
		BorderSizePixel = props.BorderSizePixel or 0,
		ZIndex = props.ZIndex,
		Ambient = lighting.ambient,
		LightDirection = Vector3.new(lighting.lightDirectionX, lighting.lightDirectionY, lighting.lightDirectionZ),
		LightColor = lighting.lightColor,
	}, if props.children then props.children else {})
end

return ModelViewport

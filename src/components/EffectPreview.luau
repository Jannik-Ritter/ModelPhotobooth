local AssetService = game:GetService("AssetService")

local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages._Index["jsdotlua_react@17.2.1"]["react"])

local postProcess = require(script.Parent.Parent.lib.postProcess)
local Store = require(script.Parent.Parent.Store)

local e = React.createElement

local CANVAS = 128
local CIRCLE_CX = 64
local CIRCLE_CY = 64
local CIRCLE_R2 = 28 * 28 -- radius 28

type Props = {
	outline: Store.OutlineState,
	dropShadow: Store.EffectState,
	innerShadow: Store.InnerShadowState,
	LayoutOrder: number?,
}

local function drawBaseCircle(): buffer
	local buf = buffer.create(CANVAS * CANVAS * 4)
	for y = 0, CANVAS - 1 do
		for x = 0, CANVAS - 1 do
			local dx = x - CIRCLE_CX
			local dy = y - CIRCLE_CY
			if dx * dx + dy * dy <= CIRCLE_R2 then
				local o = (y * CANVAS + x) * 4
				buffer.writeu8(buf, o, 255)
				buffer.writeu8(buf, o + 1, 255)
				buffer.writeu8(buf, o + 2, 255)
				buffer.writeu8(buf, o + 3, 255)
			end
		end
	end
	return buf
end

local function EffectPreview(props: Props)
	local editableImage, setEditableImage = React.useState(nil :: EditableImage?)
	local imgRef = React.useRef(nil :: EditableImage?)

	-- Regenerate preview whenever any effect setting changes.
	-- shallowMerge in the reducer creates new table identities on each dispatch,
	-- so table identity comparison correctly detects any field change.
	React.useEffect(function()
		local buf = drawBaseCircle()

		-- Apply in the same order as captureOne: inner shadow → outline → drop shadow
		if props.innerShadow.enabled then
			buf = postProcess.applyInnerShadow(
				buf, CANVAS, CANVAS,
				props.innerShadow.color,
				props.innerShadow.opacity,
				props.innerShadow.distance,
				props.innerShadow.blur,
				props.innerShadow.angle
			)
		end
		if props.outline.enabled and props.outline.thickness > 0 then
			buf = postProcess.applyOutline(
				buf, CANVAS, CANVAS,
				props.outline.color,
				props.outline.thickness
			)
		end
		if props.dropShadow.enabled then
			buf = postProcess.applyDropShadow(
				buf, CANVAS, CANVAS,
				props.dropShadow.color,
				props.dropShadow.opacity,
				props.dropShadow.distance,
				props.dropShadow.blur
			)
		end

		local img = AssetService:CreateEditableImage({ Size = Vector2.new(CANVAS, CANVAS) })
		img:WritePixelsBuffer(Vector2.zero, Vector2.new(CANVAS, CANVAS), buf)

		if imgRef.current then
			imgRef.current:Destroy()
		end
		imgRef.current = img
		setEditableImage(img)
	end, { props.outline, props.dropShadow, props.innerShadow } :: { any })

	-- Destroy image on unmount (e.g. when section is collapsed)
	React.useEffect(function()
		return function()
			if imgRef.current then
				imgRef.current:Destroy()
				imgRef.current = nil
			end
		end
	end, {} :: { any })

	return e("Frame", {
		Size = UDim2.new(1, 0, 0, 168),
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
	}, {
		canvas = e("Frame", {
			Size = UDim2.fromOffset(160, 160),
			Position = UDim2.new(0.5, -80, 0, 4),
			BackgroundColor3 = Color3.fromRGB(38, 38, 38),
			BorderSizePixel = 0,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
			image = if editableImage
				then e("ImageLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					ImageContent = Content.fromObject(editableImage),
					ScaleType = Enum.ScaleType.Fit,
				})
				else nil,
		}),
	})
end

return EffectPreview

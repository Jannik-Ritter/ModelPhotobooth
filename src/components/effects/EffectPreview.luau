local AssetService = game:GetService("AssetService")

local Packages = script.Parent.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local postProcess = require(script.Parent.Parent.Parent.lib.postProcess)
local Store = require(script.Parent.Parent.Parent.Store)

local e = React.createElement

local CANVAS = 128
local CIRCLE_CX = 64
local CIRCLE_CY = 64
local CIRCLE_R2 = 28 * 28 -- radius 28

type Props = {
	outline: Store.OutlineState,
	dropShadow: Store.EffectState,
	innerShadow: Store.InnerShadowState,
	outerGlow: Store.OuterGlowState,
	chromaticAberration: Store.ChromaticAberrationState,
	bgMode: string,
	bgColor: Color3,
	LayoutOrder: number?,
}

local function isColorNear(a: Color3, b: Color3): boolean
	local eps = 0.01
	return math.abs(a.R - b.R) <= eps and math.abs(a.G - b.G) <= eps and math.abs(a.B - b.B) <= eps
end

local function getPreviewColors(bgMode: string, bgColor: Color3): (Color3, Color3)
	-- None -> white dot on studio-like dark preview background (existing look)
	if bgMode == "transparent" then
		return Color3.new(1, 1, 1), Color3.fromRGB(38, 38, 38)
	end

	-- White export background -> white dot on black preview background
	if isColorNear(bgColor, Color3.new(1, 1, 1)) then
		return Color3.new(0, 0, 0), Color3.new(1, 1, 1)
	end

	-- Black export background (preset is near-black) -> black dot on white preview background
	if isColorNear(bgColor, Color3.fromRGB(18, 18, 18)) or isColorNear(bgColor, Color3.new(0, 0, 0)) then
		return Color3.new(1, 1, 1), Color3.new(0, 0, 0)
	end

	-- Fallback for any future custom color mode values
	return Color3.new(1, 1, 1), Color3.fromRGB(38, 38, 38)
end

local function drawBaseCircle(circleColor: Color3): buffer
	local cr = math.floor(circleColor.R * 255 + 0.5)
	local cg = math.floor(circleColor.G * 255 + 0.5)
	local cb = math.floor(circleColor.B * 255 + 0.5)
	local buf = buffer.create(CANVAS * CANVAS * 4)
	for y = 0, CANVAS - 1 do
		for x = 0, CANVAS - 1 do
			local dx = x - CIRCLE_CX
			local dy = y - CIRCLE_CY
			if dx * dx + dy * dy <= CIRCLE_R2 then
				local o = (y * CANVAS + x) * 4
				buffer.writeu8(buf, o, cr)
				buffer.writeu8(buf, o + 1, cg)
				buffer.writeu8(buf, o + 2, cb)
				buffer.writeu8(buf, o + 3, 255)
			end
		end
	end
	return buf
end

local function EffectPreview(props: Props)
	local theme = StudioComponents.useTheme()
	local editableImage, setEditableImage = React.useState(nil :: EditableImage?)
	local imgRef = React.useRef(nil :: EditableImage?)
	local dotColor, canvasColor = getPreviewColors(props.bgMode, props.bgColor)

	-- Regenerate preview whenever any effect setting changes.
	-- shallowMerge in the reducer creates new table identities on each dispatch,
	-- so table identity comparison correctly detects any field change.
	React.useEffect(
		function()
			local buf = drawBaseCircle(dotColor)

			-- Apply in the same order as renderOne: inner shadow → outline → drop shadow
			if props.innerShadow.enabled then
				buf = postProcess.applyInnerShadow(
					buf,
					CANVAS,
					CANVAS,
					props.innerShadow.color,
					props.innerShadow.opacity,
					props.innerShadow.distance,
					props.innerShadow.blur,
					props.innerShadow.angle
				)
			end
			if props.outline.enabled and props.outline.thickness > 0 then
				buf = postProcess.applyOutline(buf, CANVAS, CANVAS, props.outline.color, props.outline.thickness)
			end
			if props.dropShadow.enabled then
				buf = postProcess.applyDropShadow(
					buf,
					CANVAS,
					CANVAS,
					props.dropShadow.color,
					props.dropShadow.opacity,
					props.dropShadow.distance,
					props.dropShadow.blur,
					props.dropShadow.angle
				)
			end
			if props.outerGlow.enabled then
				buf = postProcess.applyOuterGlow(
					buf,
					CANVAS,
					CANVAS,
					props.outerGlow.color,
					props.outerGlow.size,
					props.outerGlow.opacity,
					props.outerGlow.blur
				)
			end
			if props.chromaticAberration.enabled then
				buf = postProcess.applyChromaticAberration(buf, CANVAS, CANVAS, props.chromaticAberration.amount)
			end

			local img = AssetService:CreateEditableImage({ Size = Vector2.new(CANVAS, CANVAS) })
			img:WritePixelsBuffer(Vector2.zero, Vector2.new(CANVAS, CANVAS), buf)

			if imgRef.current then
				imgRef.current:Destroy()
			end
			imgRef.current = img
			setEditableImage(img)
		end,
		{ props.outline, props.dropShadow, props.innerShadow, props.outerGlow, props.chromaticAberration, dotColor } :: { any }
	)

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
			BackgroundColor3 = if props.bgMode == "transparent"
				then theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground)
				else canvasColor,
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

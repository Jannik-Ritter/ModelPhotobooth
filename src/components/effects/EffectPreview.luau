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

	if bgMode == "custom" then
		local lum = 0.299 * bgColor.R + 0.587 * bgColor.G + 0.114 * bgColor.B
		if lum > 0.5 then
			return Color3.new(0, 0, 0), bgColor
		end
		return Color3.new(1, 1, 1), bgColor
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
	-- Debounced so rapid slider drags don't allocate a new EditableImage every frame.
	React.useEffect(
		function()
			local handle = task.delay(0.05, function()
				local buf = drawBaseCircle(dotColor)
				buf = postProcess.applyImageEffects(buf, CANVAS, CANVAS, {
					innerShadow = props.innerShadow,
					outline = props.outline,
					dropShadow = props.dropShadow,
					chromaticAberration = props.chromaticAberration,
					outerGlow = props.outerGlow,
				})

				local img = AssetService:CreateEditableImage({ Size = Vector2.new(CANVAS, CANVAS) })
				img:WritePixelsBuffer(Vector2.zero, Vector2.new(CANVAS, CANVAS), buf)

				if imgRef.current then
					imgRef.current:Destroy()
				end
				imgRef.current = img
				setEditableImage(img)
			end)
			return function()
				task.cancel(handle)
			end
		end,
		{
			props.outline,
			props.dropShadow,
			props.innerShadow,
			props.outerGlow,
			props.chromaticAberration,
			dotColor,
			props.bgMode,
			props.bgColor,
		} :: { any }
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

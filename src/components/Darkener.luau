-- Full-screen input-blocking darkened overlay.
-- Uses a TextButton root so all mouse input is captured (preventing click-through).
-- Pass children as the third argument to React.createElement.
-- Pass onBackdropClick to dismiss on backdrop click; omit for non-dismissable overlays.

local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)

local e = React.createElement

type Props = {
	ZIndex: number?,
	onBackdropClick: (() -> ())?,
}

local function Darkener(props: Props)
	return e("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = props.ZIndex,
		[React.Event.Activated] = props.onBackdropClick,
	}, props.children)
end

return Darkener

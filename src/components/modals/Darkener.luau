-- Full-screen input-blocking darkened overlay.
local Packages = script.Parent.Parent.Parent.Parent.Packages
local React = require(Packages.react)

local e = React.createElement

type Props = {
	ZIndex: number?,
	onBackdropClick: (() -> ())?,
}

local function Darkener(props: Props)
	return e("ImageButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Image = "",
		Active = false,
		ZIndex = props.ZIndex,
		[React.Event.Activated] = props.onBackdropClick,
	}, props.children)
end

return Darkener

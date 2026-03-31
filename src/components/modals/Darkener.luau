-- Full-screen input-blocking darkened overlay.
local Packages = script.Parent.Parent.Parent.Parent.Packages
local React = require(Packages.react)

local e = React.createElement

type Props = {
	ZIndex: number?,
	onBackdropClick: (() -> ())?,
}

local function Darkener(props: Props)
	return e("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingEnabled = true,
		CanvasSize = UDim2.fromScale(1, 1),
		ZIndex = props.ZIndex,
	}, {
		Backdrop = e("ImageButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Image = "",
			[React.Event.Activated] = props.onBackdropClick,
		}, {
			props.children,
		}),
	})
end

return Darkener

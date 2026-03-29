local Packages = script.Parent.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local e = React.createElement

type Props = {
	onActivated: () -> (),
	position: UDim2?,
	size: UDim2?,
}

local function ModalCloseButton(props: Props)
	return e(StudioComponents.Button, {
		OnActivated = props.onActivated,
		Icon = {
			Image = "rbxassetid://129976509676301",
			Size = Vector2.new(16, 16),
			UseThemeColor = true,
		},
		Size = props.size or UDim2.fromOffset(22, 22),
		Position = props.position or UDim2.new(1, -26, 0.5, -11),
	})
end

return ModalCloseButton

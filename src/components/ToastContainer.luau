local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)

local Toast = require(script.Parent.Toast)

local e = React.createElement

export type ToastEntry = {
	id: number,
	variant: string,
	message: string,
}

type Props = {
	toasts: { ToastEntry },
	onRemove: (id: number) -> (),
}

local function ToastContainer(props: Props)
	local children: { [string]: any } = {
		layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	for i, toast in ipairs(props.toasts) do
		children["toast_" .. toast.id] = e(Toast, {
			id = toast.id,
			variant = toast.variant,
			message = toast.message,
			LayoutOrder = i,
			onRemove = function()
				props.onRemove(toast.id)
			end,
		})
	end

	return e("Frame", {
		-- Fixed width, auto-height; anchored to bottom-center, grows upward
		Size = UDim2.fromOffset(262, 0),
		Position = UDim2.new(0.5, 0, 1, -12),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 10,
	}, children)
end

return ToastContainer

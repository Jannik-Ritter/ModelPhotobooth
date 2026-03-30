local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)

type TrackballResult = {
	onInputBegan: (rbx: GuiObject, input: InputObject) -> (),
	onInputChanged: (rbx: GuiObject, input: InputObject) -> (),
	onInputEnded: (rbx: GuiObject, input: InputObject) -> (),
	onMouseLeave: () -> (),
	isDragging: boolean,
}

local function useTrackball(onDelta: (dx: number, dy: number) -> ()): TrackballResult
	local draggingRef = React.useRef(false)
	local lastPosRef = React.useRef(Vector2.zero)
	local isDragging, setIsDragging = React.useState(false)

	local onInputBegan = React.useCallback(function(_rbx: GuiObject, input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			draggingRef.current = true
			setIsDragging(true)
			lastPosRef.current = Vector2.new(input.Position.X, input.Position.Y)
		end
	end, {})

	local onInputChanged = React.useCallback(function(_rbx: GuiObject, input: InputObject)
		if not draggingRef.current then
			return
		end
		if
			input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end
		local pos = Vector2.new(input.Position.X, input.Position.Y)
		local last = lastPosRef.current
		local dx = pos.X - last.X
		local dy = pos.Y - last.Y
		lastPosRef.current = pos
		onDelta(dx, dy)
	end, { onDelta } :: { any })

	local onInputEnded = React.useCallback(function(_rbx: GuiObject, input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			draggingRef.current = false
			setIsDragging(false)
		end
	end, {})

	local onMouseLeave = React.useCallback(function()
		draggingRef.current = false
		setIsDragging(false)
	end, {})

	return {
		onInputBegan = onInputBegan,
		onInputChanged = onInputChanged,
		onInputEnded = onInputEnded,
		onMouseLeave = onMouseLeave,
		isDragging = isDragging,
	}
end

return useTrackball

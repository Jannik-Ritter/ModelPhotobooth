local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local Store = require(script.Parent.Parent.Store)

return function(
	dispatch: (any) -> (),
	animationPlayingRef: { current: boolean },
	activeAnimationIndexRef: { current: number? }
)
	local activeInputsRef = React.useRef({} :: { [Enum.KeyCode]: boolean })
	local shiftDown, setShiftDown = React.useState(false)

	local function isKeyDown(key: Enum.KeyCode)
		return activeInputsRef.current[key]
	end

	local function isCtrlDown()
		return isKeyDown(Enum.KeyCode.LeftControl) or isKeyDown(Enum.KeyCode.RightControl)
	end

	local function isShiftDown()
		return isKeyDown(Enum.KeyCode.LeftShift) or isKeyDown(Enum.KeyCode.RightShift)
	end

	local function onWidgetInputBegan(_, input)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			activeInputsRef.current[input.KeyCode] = true
			if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
				setShiftDown(
					activeInputsRef.current[Enum.KeyCode.LeftShift] == true
						or activeInputsRef.current[Enum.KeyCode.RightShift] == true
				)
			end
			if input.KeyCode == Enum.KeyCode.Space and activeAnimationIndexRef.current then
				dispatch({
					type = Store.ACTIONS.SET_ANIMATION_PLAYING,
					value = not animationPlayingRef.current,
				})
			end
		end
	end

	local function onWidgetInputEnded(_, input)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			activeInputsRef.current[input.KeyCode] = nil
			if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
				setShiftDown(
					activeInputsRef.current[Enum.KeyCode.LeftShift] == true
						or activeInputsRef.current[Enum.KeyCode.RightShift] == true
				)
			end
		end
	end

	local inputCaptureProps = {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Active = true,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 9999,
		[React.Event.InputBegan] = onWidgetInputBegan,
		[React.Event.InputEnded] = onWidgetInputEnded,
	}

	return {
		inputCaptureProps = inputCaptureProps,
		isCtrlDown = isCtrlDown,
		isShiftDown = isShiftDown,
		shiftDown = shiftDown,
		activeInputsRef = activeInputsRef,
	}
end

local TweenService = game:GetService("TweenService")

local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)

local e = React.createElement

local TOAST_HEIGHT = 44

local VARIANT_ACCENT = {
	normal = Color3.fromRGB(80, 140, 220),
	success = Color3.fromRGB(50, 190, 90),
	error = Color3.fromRGB(215, 60, 60),
}

local VARIANT_ICON = {
	normal = "rbxassetid://90323797666287",
	success = "rbxassetid://130016483841149",
	error = "rbxassetid://129976509676301",
}

local VARIANT_DURATION = {
	normal = 4,
	success = 4,
	error = 6,
}

type Props = {
	id: number,
	variant: string,
	message: string,
	LayoutOrder: number,
	onRemove: () -> (),
	onHelp: (() -> ())?,
}

local function Toast(props: Props)
	local slotRef = React.useRef(nil :: Frame?)
	local contentRef = React.useRef(nil :: Frame?)
	local dismissed, setDismissed = React.useState(false)

	-- Slide in from the right on mount
	React.useEffect(function()
		local content = contentRef.current
		if not content then
			return
		end
		content.Position = UDim2.fromOffset(0, TOAST_HEIGHT + 6)
		local tween = TweenService:Create(
			content,
			TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Position = UDim2.fromOffset(0, 0) }
		)
		tween:Play()
	end, {} :: { any })

	-- Auto-dismiss timer
	React.useEffect(function()
		local duration = VARIANT_DURATION[props.variant] or 4
		local handle = task.delay(duration, function()
			setDismissed(true)
		end)
		return function()
			task.cancel(handle)
		end
	end, {} :: { any })

	-- Slide out downward, then collapse the slot height
	React.useEffect(function()
		if not dismissed then
			return
		end
		local slot = slotRef.current
		local content = contentRef.current
		if not slot or not content then
			props.onRemove()
			return
		end
		local slideTween = TweenService:Create(
			content,
			TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
			{ Position = UDim2.fromOffset(0, TOAST_HEIGHT + 6) }
		)
		slideTween:Play()
		slideTween.Completed:Connect(function()
			if not slot.Parent then
				props.onRemove()
				return
			end
			local collapseTween = TweenService:Create(
				slot,
				TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
				{ Size = UDim2.new(1, 0, 0, 0) }
			)
			collapseTween:Play()
			collapseTween.Completed:Connect(function()
				props.onRemove()
			end)
		end)
	end, { dismissed } :: { any })

	local accent = VARIANT_ACCENT[props.variant] or VARIANT_ACCENT.normal
	local icon = VARIANT_ICON[props.variant] or VARIANT_ICON.normal

	return e("Frame", {
		-- Outer slot: controls height in the UIListLayout; ClipsDescendants hides the slide animation
		Size = UDim2.new(1, 0, 0, TOAST_HEIGHT),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		LayoutOrder = props.LayoutOrder,
		ref = slotRef,
	}, {
		content = e("ImageButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(36, 36, 39),
			BorderSizePixel = 0,
			ref = contentRef,
			Image = "",
			[React.Event.Activated] = function()
				if props.variant == "error" and props.onHelp then
					props.onHelp()
				end
				setDismissed(true)
			end,
		}, {
			border = e("UIStroke", {
				Color = Color3.fromRGB(0, 0, 0),
				Transparency = 0.55,
				Thickness = 1,
			}),
			-- Left accent stripe
			stripe = e("Frame", {
				Size = UDim2.new(0, 3, 1, 0),
				Position = UDim2.fromOffset(0, 0),
				BackgroundColor3 = accent,
				BorderSizePixel = 0,
				ZIndex = 2,
			}, {
				corner = e("UICorner", { CornerRadius = UDim.new(0, 2) }),
			}),
			-- Icon badge
			badge = e("ImageLabel", {
				Size = UDim2.fromOffset(18, 18),
				Position = UDim2.new(1, -11, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = accent,
				BorderSizePixel = 0,
				Image = icon,
				ImageColor3 = Color3.new(1, 1, 1),
				ZIndex = 2,
			}, {
				corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
			}),
			-- Message
			message = e("TextLabel", {
				-- from x=37 (stripe+badge+gap) to x=width-32 (close btn)
				Size = UDim2.new(1, 22 - 32, 1, 0),
				Position = UDim2.fromOffset(11, 0),
				BackgroundTransparency = 1,
				Text = props.message,
				TextColor3 = Color3.fromRGB(215, 215, 215),
				Font = Enum.Font.Gotham,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 2,
			}),
		}),
	})
end

return Toast

local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)

local e = React.createElement

type AnimationInfo = {
	name: string,
	animationId: string,
}

type Props = {
	animations: { AnimationInfo },
	activeAnimationIndex: number?,
	playing: boolean,
	timePosition: number,
	length: number,
	onSelectAnimation: (index: number?) -> (),
	onSetPlaying: (playing: boolean) -> (),
	onSetTimePosition: (time: number) -> (),
}

local function formatTime(seconds: number): string
	return string.format("%.1f", math.max(0, seconds))
end

local function AnimationPanel(props: Props)
	local theme = StudioComponents.useTheme()
	local scrubbingRef = React.useRef(false)
	local wasPlayingRef = React.useRef(false)
	local barRef = React.useRef(nil :: GuiObject?)
	local lengthRef = React.useRef(props.length)
	local playingRef = React.useRef(props.playing)

	React.useEffect(function()
		lengthRef.current = props.length
	end, { props.length })

	React.useEffect(function()
		playingRef.current = props.playing
	end, { props.playing })

	local hasActive = props.activeAnimationIndex ~= nil
	local panelHeight = if hasActive then 56 else 28

	-- Animation list buttons
	local animChildren = {}
	animChildren.layout = e("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
	})

	for i, anim in ipairs(props.animations) do
		local isActive = props.activeAnimationIndex == i
		animChildren["anim_" .. i] = e("TextButton", {
			Text = anim.name,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			BackgroundColor3 = if isActive
				then theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton)
				else Color3.new(0, 0, 0),
			BackgroundTransparency = if isActive then 0 else 0.5,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 11,
			Font = Enum.Font.SourceSans,
			BorderSizePixel = 0,
			LayoutOrder = i,
			ZIndex = 22,
			[React.Event.Activated] = function()
				if isActive then
					props.onSelectAnimation(nil)
				else
					props.onSelectAnimation(i)
				end
			end,
		}, {
			corner = e("UICorner", { CornerRadius = UDim.new(0, 3) }),
			padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 6),
				PaddingRight = UDim.new(0, 6),
			}),
		})
	end

	-- Scrubber
	local progress = if props.length > 0 then math.clamp(props.timePosition / props.length, 0, 1) else 0

	local function onScrubInput(input: InputObject)
		local bar = barRef.current
		if not bar then
			return
		end
		local relX = input.Position.X - bar.AbsolutePosition.X
		local fraction = math.clamp(relX / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		props.onSetTimePosition(fraction * lengthRef.current)
	end

	-- Transport controls
	local transport = nil
	if hasActive then
		transport = e("Frame", {
			Size = UDim2.new(1, 0, 0, 24),
			Position = UDim2.new(0, 0, 0, 28),
			BackgroundTransparency = 1,
			ZIndex = 21,
		}, {
			playBtn = e("TextButton", {
				Text = if props.playing then "\u{23F9}" else "\u{25B6}",
				Size = UDim2.fromOffset(24, 24),
				Position = UDim2.fromOffset(4, 0),
				BackgroundColor3 = Color3.new(0, 0, 0),
				BackgroundTransparency = 0.5,
				TextColor3 = Color3.new(1, 1, 1),
				TextSize = 12,
				Font = Enum.Font.SourceSans,
				BorderSizePixel = 0,
				ZIndex = 22,
				[React.Event.Activated] = function()
					props.onSetPlaying(not playingRef.current)
				end,
			}, {
				corner = e("UICorner", { CornerRadius = UDim.new(0, 3) }),
			}),

			scrubber = e("ImageButton", {
				ref = barRef,
				Size = UDim2.new(1, -96, 0, 24),
				Position = UDim2.fromOffset(32, 0),
				BackgroundTransparency = 1,
				ImageTransparency = 1,
				AutoButtonColor = false,
				ZIndex = 22,
				[React.Event.InputBegan] = function(_, input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						scrubbingRef.current = true
						wasPlayingRef.current = playingRef.current
						if playingRef.current then
							props.onSetPlaying(false)
						end
						onScrubInput(input)
					end
				end,
				[React.Event.InputChanged] = function(_, input)
					if scrubbingRef.current and input.UserInputType == Enum.UserInputType.MouseMovement then
						onScrubInput(input)
					end
				end,
				[React.Event.InputEnded] = function(_, input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 and scrubbingRef.current then
						scrubbingRef.current = false
						if wasPlayingRef.current then
							props.onSetPlaying(true)
						end
					end
				end,
				[React.Event.MouseLeave] = function()
					if scrubbingRef.current then
						scrubbingRef.current = false
						if wasPlayingRef.current then
							props.onSetPlaying(true)
						end
					end
				end,
			}, {
				track = e("Frame", {
					Size = UDim2.new(1, 0, 0, 6),
					Position = UDim2.new(0, 0, 0.5, -3),
					BackgroundColor3 = Color3.fromRGB(60, 60, 60),
					BorderSizePixel = 0,
					ZIndex = 23,
				}, {
					corner = e("UICorner", { CornerRadius = UDim.new(0, 3) }),
					fill = e("Frame", {
						Size = UDim2.new(progress, 0, 1, 0),
						BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton),
						BorderSizePixel = 0,
						ZIndex = 24,
					}, {
						corner = e("UICorner", { CornerRadius = UDim.new(0, 3) }),
					}),
				}),
				handle = e("Frame", {
					Size = UDim2.fromOffset(10, 10),
					Position = UDim2.new(progress, -5, 0.5, -5),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0,
					ZIndex = 25,
				}, {
					corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
				}),
			}),

			timeLabel = e("TextLabel", {
				Text = formatTime(props.timePosition) .. " / " .. formatTime(props.length),
				Size = UDim2.new(0, 56, 1, 0),
				Position = UDim2.new(1, -60, 0, 0),
				BackgroundTransparency = 1,
				TextColor3 = Color3.new(1, 1, 1),
				TextSize = 11,
				Font = Enum.Font.SourceSans,
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = 22,
			}),
		})
	end

	return e("Frame", {
		Size = UDim2.new(1, 0, 0, panelHeight),
		Position = UDim2.new(0, 0, 1, -panelHeight),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		ZIndex = 20,
		ClipsDescendants = true,
	}, {
		corner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
		animList = e("Frame", {
			Size = UDim2.new(1, -8, 0, 22),
			Position = UDim2.fromOffset(4, 3),
			BackgroundTransparency = 1,
			ZIndex = 21,
			ClipsDescendants = true,
		}, animChildren),
		transport = transport,
	})
end

return AnimationPanel

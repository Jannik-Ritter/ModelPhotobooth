local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)
local Types = require(script.Parent.Parent.Types)

local limitDecimals = require(script.Parent.Parent.utils.limitDecimals)

local e = React.createElement

type AnimationInfo = Types.AnimationInfo

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
	return limitDecimals(math.max(0, seconds), 1)
end

local function AnimationPanel(props: Props)
	local theme = StudioComponents.useTheme()
	local scrubbingRef = React.useRef(false)
	local wasPlayingRef = React.useRef(false)
	local playingRef = React.useRef(props.playing)

	React.useEffect(function()
		playingRef.current = props.playing
	end, { props.playing })

	local hasActive = props.activeAnimationIndex ~= nil
	local panelHeight = if hasActive then 56 else 28

	local lengthMax = math.max(props.length, 1e-4)
	local sliderDisabled = props.length <= 0

	local function onSliderChanged(v: number)
		if not scrubbingRef.current then
			scrubbingRef.current = true
			wasPlayingRef.current = playingRef.current
			if playingRef.current then
				props.onSetPlaying(false)
			end
		end
		props.onSetTimePosition(v)
	end

	local function onSliderCompleted(_v: number)
		scrubbingRef.current = false
		if wasPlayingRef.current then
			props.onSetPlaying(true)
		end
		wasPlayingRef.current = false
	end

	local animChildren: { [string]: any } = {}
	animChildren.layout = e("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})

	for i, anim in ipairs(props.animations) do
		local isActive = props.activeAnimationIndex == i
		local Btn = if isActive then StudioComponents.MainButton else StudioComponents.Button
		animChildren["anim_" .. i] = e(Btn, {
			Text = anim.name,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromScale(0, 1),
			LayoutOrder = i,
			ZIndex = 22,
			OnActivated = function()
				if isActive then
					props.onSelectAnimation(nil)
				else
					props.onSelectAnimation(i)
				end
			end,
		})
	end

	local transport = nil
	if hasActive then
		transport = e("Frame", {
			Size = UDim2.new(1, 0, 0, 22),
			Position = UDim2.fromOffset(0, 30),
			BackgroundTransparency = 1,
			ZIndex = 21,
		}, {
			layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6),
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			playBtn = e(if props.playing then StudioComponents.MainButton else StudioComponents.Button, {
				Icon = {
					Image = if props.playing then "rbxassetid://120342180359733" else "rbxassetid://136943897636322",
					Size = Vector2.new(16, 16),
					UseThemeColor = true,
				},
				Size = UDim2.fromOffset(28, 22),
				LayoutOrder = 1,
				ZIndex = 22,
				OnActivated = function()
					props.onSetPlaying(not playingRef.current)
				end,
			}),
			scrubber = e(StudioComponents.Slider, {
				Value = math.clamp(props.timePosition, 0, lengthMax),
				Min = 0,
				Max = lengthMax,
				Step = 0,
				Disabled = sliderDisabled,
				OnChanged = onSliderChanged,
				OnCompleted = onSliderCompleted,
				Size = UDim2.new(1, -90, 0, 22),
				LayoutOrder = 2,
				ZIndex = 22,
			}),
			timeLabel = e(StudioComponents.Label, {
				Text = formatTime(props.timePosition) .. " / " .. formatTime(props.length),
				Size = UDim2.new(0, 56, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Center,
				LayoutOrder = 3,
				ZIndex = 22,
			}),
		})
	end

	return e("Frame", {
		Size = UDim2.new(1, 0, 0, panelHeight),
		Position = UDim2.new(0, 0, 1, -panelHeight),
		BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		ZIndex = 20,
		ClipsDescendants = true,
	}, {
		animList = e("ScrollingFrame", {
			Size = UDim2.new(1, -8, 0, 22),
			Position = UDim2.fromOffset(4, 4),
			BackgroundTransparency = 1,
			ZIndex = 21,
			ClipsDescendants = true,
			ScrollingDirection = Enum.ScrollingDirection.X,
			CanvasSize = UDim2.fromScale(0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.X,
			ScrollBarThickness = 0,
		}, animChildren),
		transport = transport,
	})
end

return AnimationPanel

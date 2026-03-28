local Packages = script.Parent.Parent.Packages
local React = require(Packages._Index["jsdotlua_react@17.2.1"]["react"])
local StudioComponents = require(Packages.studiocomponents)

local Selection = game:GetService("Selection")
local CollectionService = game:GetService("CollectionService")

local Store = require(script.Parent.Store)
local captureOne = require(script.Parent.lib.captureOne)
local exportAll = require(script.Parent.lib.exportAll)
local ToolbarStrip = require(script.Parent.components.ToolbarStrip)
local PreviewViewport = require(script.Parent.components.PreviewViewport)
local ModelStrip = require(script.Parent.components.ModelStrip)
local Sidebar = require(script.Parent.components.Sidebar)
local ImagePreviewModal = require(script.Parent.components.ImagePreviewModal)
local ColorPickerModal = require(script.Parent.components.ColorPickerModal)
local Darkener = require(script.Parent.components.Darkener)

local e = React.createElement
local MPB_TAG = "_MPBIcon"

type Props = {
	plugin: any,
}

local function App(props: Props)
	local state, dispatch = React.useReducer(Store.reducer, Store.DEFAULT_STATE)
	local capturingRef = React.useRef(false)
	local modelsRef = React.useRef(Store.DEFAULT_STATE.models)

	-- Keep modelsRef current so the selection listener can access latest captures
	React.useEffect(function()
		modelsRef.current = state.models
	end)

	-- Selection listener
	React.useEffect(function()
		local function refresh()
			-- Build a lookup of existing entries by instance to preserve captures
			local existing: { [Instance]: Store.ModelEntry } = {}
			for _, entry in ipairs(modelsRef.current) do
				existing[entry.instance] = entry
			end

			local sel = Selection:Get()
			local models: { Store.ModelEntry } = {}
			for _, obj in ipairs(sel) do
				if CollectionService:HasTag(obj, MPB_TAG) then
					table.insert(models, {
						instance = obj,
						status = "ok" :: Store.CaptureStatus,
						image = nil,
						isExported = true,
					})
				elseif obj:IsA("Model") or obj:IsA("BasePart") then
					local prev = existing[obj]
					table.insert(models, {
						instance = obj,
						status = if prev then prev.status else "idle" :: Store.CaptureStatus,
						image = if prev then prev.image else nil,
						isExported = false,
					})
				end
			end
			dispatch({ type = Store.ACTIONS.SET_MODELS, value = models })
			-- Auto-select first model
			if #models > 0 then
				dispatch({ type = Store.ACTIONS.SET_ACTIVE_MODEL_INDEX, value = 1 })
			else
				dispatch({ type = Store.ACTIONS.SET_ACTIVE_MODEL_INDEX, value = 0 })
			end
		end
		local conn = Selection.SelectionChanged:Connect(refresh)
		refresh()
		return function()
			conn:Disconnect()
		end
	end, {} :: { any })

	-- Capture all
	local function startCapture()
		if capturingRef.current then
			return
		end
		capturingRef.current = true
		dispatch({ type = Store.ACTIONS.SET_CAPTURING, capturing = true, progress = 0 })

		task.spawn(function()
			local models = state.models
			for i, entry in ipairs(models) do
				if entry.isExported then
					continue
				end
				dispatch({ type = Store.ACTIONS.SET_CAPTURE_STATUS, index = i, status = "pending" })
				dispatch({ type = Store.ACTIONS.SET_CAPTURING, capturing = true, progress = i - 1 })

				local img = captureOne(entry.instance, {
					yaw = state.yaw,
					pitch = state.pitch,
					fov = state.fov,
					outline = state.outline,
					dropShadow = state.dropShadow,
					innerShadow = state.innerShadow,
					bgMode = state.bgMode,
					bgColor = state.bgColor,
					exportSize = state.exportSize,
				})

				dispatch({
					type = Store.ACTIONS.SET_CAPTURE_STATUS,
					index = i,
					status = if img then "ok" else "fail",
					image = img,
				})
				dispatch({ type = Store.ACTIONS.SET_CAPTURING, capturing = true, progress = i })
				task.wait()
			end
			dispatch({ type = Store.ACTIONS.SET_CAPTURING, capturing = false, progress = 0 })
			capturingRef.current = false
		end)
	end

	-- Export all
	local function doExport()
		local parts = exportAll(state.models)
		if #parts > 0 then
			pcall(function()
				Selection:Set(parts)
			end)
		end
	end

	-- Trackball handler
	local function onTrackball(dYaw: number, dPitch: number)
		dispatch({
			type = Store.ACTIONS.SET_CAMERA,
			yaw = state.yaw + dYaw,
			pitch = state.pitch + dPitch,
			fov = state.fov,
		})
	end

	-- Status text
	local capturedCount = 0
	local totalCount = 0
	for _, entry in ipairs(state.models) do
		if not entry.isExported then
			totalCount += 1
			if entry.status == "ok" then
				capturedCount += 1
			end
		end
	end

	local statusText
	if capturedCount > 0 and not state.capturing then
		statusText = `{capturedCount}/{totalCount} captured`
	elseif #state.models > 0 then
		statusText = `{#state.models} model(s) selected`
	else
		statusText = "Ready"
	end

	local hasCaptures = false
	for _, entry in ipairs(state.models) do
		if entry.image then
			hasCaptures = true
			break
		end
	end

	-- Active model entry
	local activeEntry = state.models[state.activeModelIndex]

	return e(StudioComponents.PluginProvider, {
		Plugin = props.plugin,
	}, {
		background = e(StudioComponents.Background, {
			Size = UDim2.fromScale(1, 1),
		}, {
			toolbar = e(ToolbarStrip, {
				statusText = statusText,
				capturing = state.capturing,
				onCapture = startCapture,
				onExport = doExport,
				captureDisabled = totalCount == 0,
				exportDisabled = not hasCaptures,
			}),
			content = e("Frame", {
				Size = UDim2.new(1, 0, 1, -36),
				Position = UDim2.new(0, 0, 0, 36),
				BackgroundTransparency = 1,
			}, {
				preview = e(PreviewViewport, {
					entry = activeEntry,
					yaw = state.yaw,
					pitch = state.pitch,
					fov = state.fov,
					onTrackball = onTrackball,
				}),
				modelStrip = e(ModelStrip, {
					models = state.models,
					activeModelIndex = state.activeModelIndex,
					yaw = state.yaw,
					pitch = state.pitch,
					fov = state.fov,
					onSelectModel = function(index)
						dispatch({ type = Store.ACTIONS.SET_ACTIVE_MODEL_INDEX, value = index })
					end,
					onPreviewModel = function(index)
						local entry = state.models[index]
						if entry and entry.image then
							dispatch({
								type = Store.ACTIONS.SET_PREVIEW_IMAGE,
								image = entry.image,
								title = entry.instance.Name,
							})
						end
					end,
				}),
				sidebar = e(Sidebar, {
					state = state,
					dispatch = dispatch,
				}),
			}),
			captureOverlay = if state.capturing and totalCount > 0
				then e(Darkener, {}, {
					progressBox = e("Frame", {
						Size = UDim2.fromOffset(260, 64),
						Position = UDim2.fromScale(0.5, 0.5),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(40, 40, 40),
						BorderSizePixel = 0,
					}, {
						label = e("TextLabel", {
							Text = string.format("Capturing %d / %d...", state.captureProgress, totalCount),
							Size = UDim2.new(1, 0, 0, 20),
							Position = UDim2.fromOffset(0, 12),
							BackgroundTransparency = 1,
							TextColor3 = Color3.fromRGB(220, 220, 220),
							TextSize = 13,
							Font = Enum.Font.SourceSansSemibold,
							TextXAlignment = Enum.TextXAlignment.Center,
							ZIndex = 20,
						}),
						bar = e(StudioComponents.ProgressBar, {
							Value = state.captureProgress / totalCount,
							Formatter = function(_, _)
								return "" -- this is intentional to hide the text
							end,
							Size = UDim2.new(1, -32, 0, 6),
							Position = UDim2.fromOffset(16, 40),
						}),
					}),
				})
				else nil,
			imagePreview = if state.previewImage
				then e(ImagePreviewModal, {
					image = state.previewImage,
					title = state.previewTitle or "Preview",
					onClose = function()
						dispatch({
							type = Store.ACTIONS.SET_PREVIEW_IMAGE,
							image = nil,
							title = nil,
						})
					end,
				})
				else nil,
			colorPickerModal = if state.colorPickerTarget ~= nil then (function()
				local A = Store.ACTIONS
				local target = state.colorPickerTarget
				local title, color, action
				if target == "outline" then
					title = "Outline Color"
					color = state.outline.color
					action = A.SET_OUTLINE
				elseif target == "shadow" then
					title = "Shadow Color"
					color = state.dropShadow.color
					action = A.SET_DROP_SHADOW
				else
					title = "Inner Shadow Color"
					color = state.innerShadow.color
					action = A.SET_INNER_SHADOW
				end
				return e(ColorPickerModal, {
					title = title,
					color = color,
					onColorChanged = function(c)
						dispatch({ type = action, value = { color = c } })
					end,
					onClose = function()
						dispatch({ type = A.SET_COLOR_PICKER_TARGET, value = nil })
					end,
				})
			end)() else nil,
		}),
	})
end

return App

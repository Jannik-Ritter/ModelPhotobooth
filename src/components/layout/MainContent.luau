local Packages = script.Parent.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local StudioComponents = require(Packages.studiocomponents)
local Store = require(script.Parent.Parent.Parent.Store)
local PreviewViewport = require(script.Parent.Parent.PreviewViewport)
local ModelStrip = require(script.Parent.Parent.ModelStrip)
local RenderStrip = require(script.Parent.Parent.RenderStrip)
local Sidebar = require(script.Parent.Parent.Sidebar)
local ToolbarStrip = require(script.Parent.Parent.ToolbarStrip)

local e = React.createElement

type Props = {
	inputCaptureProps: { [string]: any },
	sidebarAlpha: number,
	setSidebarAlpha: (number) -> (),
	modelStripAlpha: number,
	setModelStripAlpha: (number) -> (),
	stripTab: string,
	setStripTab: (string) -> (),
	shiftDown: boolean,
	isShiftDown: () -> boolean,
	activeEntry: Store.ModelEntry?,
	onTrackball: (number, number) -> (),
	onTranslate: (number, number, number) -> (),
	onScroll: (number) -> (),
	onResetCamera: () -> (),
	onSelectAnimation: (number?) -> (),
	onSetPlaying: (boolean) -> (),
	onSetTimePosition: (number) -> (),
	onSetLength: (number) -> (),
	onSelectModel: (number) -> (),
	onPreviewModel: (number) -> (),
	onPreviewRender: (number) -> (),
	onSavePreset: () -> (),
	onApplyPreset: (number) -> (),
	onRenamePreset: (number) -> (),
	onDeletePreset: (number) -> (),
	onRender: () -> (),
	onRenderAll: () -> (),
	onExport: () -> (),
	onUploadAll: () -> (),
	onHelp: () -> (),
}

local function MainContent(props: Props)
	return e(StudioComponents.Background, {
		Size = UDim2.fromScale(1, 1),
	}, {
		inputCapture = e("TextButton", props.inputCaptureProps, {
			toolbar = e(ToolbarStrip, {
				onRender = props.onRender,
				onRenderAll = props.onRenderAll,
				onExport = props.onExport,
				onUploadAll = props.onUploadAll,
				onHelp = props.onHelp,
			}),
			content = e("Frame", {
				Size = UDim2.new(1, 0, 1, -36),
				Position = UDim2.fromOffset(0, 36),
				BackgroundTransparency = 1,
			}, {
				mainSplitter = e(StudioComponents.Splitter, {
					Alpha = props.sidebarAlpha,
					OnChanged = props.setSidebarAlpha,
					FillDirection = Enum.FillDirection.Horizontal,
				}, {
					Side0 = e(StudioComponents.Splitter, {
						Alpha = props.modelStripAlpha,
						OnChanged = props.setModelStripAlpha,
						FillDirection = Enum.FillDirection.Vertical,
					}, {
						Side0 = e(PreviewViewport, {
							entry = props.activeEntry,
							onTrackball = props.onTrackball,
							onTranslate = props.onTranslate,
							onScroll = props.onScroll,
							onResetCamera = props.onResetCamera,
							isShiftDown = props.isShiftDown,
							shiftDown = props.shiftDown,
							onSelectAnimation = props.onSelectAnimation,
							onSetPlaying = props.onSetPlaying,
							onSetTimePosition = props.onSetTimePosition,
							onSetLength = props.onSetLength,
						}),
						Side1 = e("Frame", {
							Size = UDim2.fromScale(1, 1),
							BackgroundTransparency = 1,
						}, {
							tabs = e(StudioComponents.TabContainer, {
								Size = UDim2.fromScale(1, 1),
								SelectedTab = props.stripTab,
								OnTabSelected = props.setStripTab,
							}, {
								["Models"] = {
									LayoutOrder = 1,
									Content = e(ModelStrip, {
										onSelectModel = props.onSelectModel,
										onPreviewModel = props.onPreviewModel,
									}),
								},
								["Renders"] = {
									LayoutOrder = 2,
									Content = e(RenderStrip, {
										onPreviewRender = props.onPreviewRender,
									}),
								},
							}),
						}),
					}),
					Side1 = e(Sidebar, {
						onSavePreset = props.onSavePreset,
						onApplyPreset = props.onApplyPreset,
						onRenamePreset = props.onRenamePreset,
						onDeletePreset = props.onDeletePreset,
					}),
				}),
			}),
		}),
	})
end

return MainContent

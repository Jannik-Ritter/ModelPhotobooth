-- Centralized type definitions
-- All modules should require this module instead of defining types locally.

export type AnimationInfo = {
	name: string,
	animationId: string,
}

export type RenderStatus = "idle" | "pending" | "ok" | "fail"

export type RenderHistoryEntry = {
	image: EditableImage,
	modelName: string,
	modelIndex: number?,
}

export type ModelEntry = {
	instance: Instance,
	status: RenderStatus,
	image: EditableImage?,
	isExported: boolean,
}

export type OutlineState = {
	enabled: boolean,
	color: Color3,
	thickness: number,
}

export type EffectState = {
	enabled: boolean,
	color: Color3,
	opacity: number,
	distance: number,
	blur: number,
	angle: number,
}

export type InnerShadowState = {
	enabled: boolean,
	color: Color3,
	opacity: number,
	distance: number,
	blur: number,
	angle: number,
}

export type OuterGlowState = {
	enabled: boolean,
	color: Color3,
	size: number,
	opacity: number,
	blur: number,
}

export type ChromaticAberrationState = {
	enabled: boolean,
	distance: number,
	opacity: number,
	angle: number,
}

export type LightingState = {
	lightColor: Color3,
	ambient: Color3,
	lightDirectionX: number,
	lightDirectionY: number,
	lightDirectionZ: number,
}

export type PresetEntry = {
	name: string,
	yaw: number,
	pitch: number,
	roll: number,
	fov: number,
	cameraDistance: number,
	cameraOffsetX: number,
	cameraOffsetY: number,
	cameraOffsetZ: number,
	bgMode: string,
	bgColor: Color3,
	exportSize: number,
	outline: OutlineState,
	dropShadow: EffectState,
	innerShadow: InnerShadowState,
	outerGlow: OuterGlowState,
	chromaticAberration: ChromaticAberrationState,
	lighting: LightingState,
}

export type NameInputModalState = {
	mode: "save" | "rename",
	targetIndex: number?,
	initialName: string?,
}

export type AppState = {
	yaw: number,
	pitch: number,
	roll: number,
	fov: number,
	cameraDistance: number,
	cameraOffsetX: number,
	cameraOffsetY: number,
	cameraOffsetZ: number,
	outline: OutlineState,
	dropShadow: EffectState,
	innerShadow: InnerShadowState,
	outerGlow: OuterGlowState,
	chromaticAberration: ChromaticAberrationState,
	lighting: LightingState,
	bgMode: string,
	bgColor: Color3,
	exportSize: number,
	models: { ModelEntry },
	renderHistory: { RenderHistoryEntry },
	rendering: boolean,
	renderProgress: number,
	renderTotal: number,
	selectedModelIndices: { number },
	collapsedSections: { [string]: boolean },
	colorPickerTarget: string?,
	previewImage: EditableImage?,
	previewTitle: string?,
	previewModelIndex: number?,
	previewHistoryIndex: number?,
	presets: { PresetEntry },
	nameInputModal: NameInputModalState?,
	animations: { AnimationInfo },
	activeAnimationIndex: number?,
	animationPlaying: boolean,
	animationTimePosition: number,
	animationLength: number,
}

export type StoreContextValue = {
	state: AppState,
	dispatch: (any) -> (),
}

export type BoundsSnapshot = {
	cf: CFrame,
	size: Vector3,
}

export type CameraParams = {
	yaw: number,
	pitch: number,
	roll: number,
	fov: number,
	cameraDistance: number,
	offsetX: number,
	offsetY: number,
	offsetZ: number,
}

export type ImageEffectsBundle = {
	innerShadow: InnerShadowState,
	outline: OutlineState,
	dropShadow: EffectState,
	chromaticAberration: ChromaticAberrationState,
	outerGlow: OuterGlowState,
}

export type RenderSettings = {
	yaw: number,
	pitch: number,
	roll: number,
	fov: number,
	cameraDistance: number,
	cameraOffsetX: number,
	cameraOffsetY: number,
	cameraOffsetZ: number,
	outline: OutlineState,
	dropShadow: EffectState,
	innerShadow: InnerShadowState,
	outerGlow: OuterGlowState,
	chromaticAberration: ChromaticAberrationState,
	lighting: LightingState,
	bgMode: string,
	bgColor: Color3,
	exportSize: number,
	animationId: string?,
	animationTimePosition: number?,
}

export type CaptureViewport = {
	gui: ScreenGui,
	bgFrame: Frame,
	viewport: ViewportFrame,
	camera: Camera,
	modelClone: Instance,
}

export type ToastEntry = {
	id: number,
	variant: string,
	message: string,
}

export type UploadResult = {
	name: string,
	assetId: number?,
	image: EditableImage?,
}

export type ToastFn = (string, string) -> ()

export type TrackballResult = {
	onInputBegan: (rbx: GuiObject, input: InputObject) -> (),
	onInputChanged: (rbx: GuiObject, input: InputObject) -> (),
	onInputEnded: (rbx: GuiObject, input: InputObject) -> (),
	onMouseLeave: () -> (),
	isDragging: boolean,
}

export type PickerConfig = {
	title: string,
	getColor: (AppState) -> Color3,
	makeAction: (Color3) -> { [string]: any },
}

return true

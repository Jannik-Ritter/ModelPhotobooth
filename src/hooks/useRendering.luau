local Store = require(script.Parent.Parent.Store)
local Types = require(script.Parent.Parent.Types)
local renderOne = require(script.Parent.Parent.lib.renderOne)
local buildRenderSettings = require(script.Parent.Parent.utils.buildRenderSettings)

type ToastFn = Types.ToastFn

local function runRenderBatch(
	targets: { { index: number, entry: Store.ModelEntry } },
	dispatch: (any) -> (),
	settings: { [string]: any },
	addToast: ToastFn,
	animationPlayingRef: { current: boolean },
	renderingRef: { current: boolean }
)
	if animationPlayingRef.current then
		dispatch({ type = Store.ACTIONS.SET_ANIMATION_PLAYING, value = false })
	end

	task.spawn(function()
		local failCount = 0
		local successCount = 0
		for i, target in ipairs(targets) do
			dispatch({ type = Store.ACTIONS.SET_RENDER_STATUS, index = target.index, status = "pending" })
			dispatch({ type = Store.ACTIONS.SET_RENDERING, rendering = true, progress = i - 1, total = #targets })

			local ok, img = renderOne(target.entry.instance, settings):await()
			if ok then
				successCount += 1
			else
				failCount += 1
			end
			dispatch({
				type = Store.ACTIONS.SET_RENDER_STATUS,
				index = target.index,
				status = if ok then "ok" else "fail",
				image = if ok then img else nil,
			})
			if ok and img then
				dispatch({
					type = Store.ACTIONS.SET_RENDER_HISTORY_ENTRY,
					image = img,
					modelName = target.entry.instance.Name,
					modelIndex = target.index,
				})
			end
			dispatch({ type = Store.ACTIONS.SET_RENDERING, rendering = true, progress = i, total = #targets })
			task.wait()
		end
		dispatch({ type = Store.ACTIONS.SET_RENDERING, rendering = false, progress = 0, total = 0 })
		renderingRef.current = false

		if failCount > 0 and successCount == 0 then
			addToast(
				"error",
				if #targets == 1
					then "Render failed: Studio viewport too small"
					else `All {failCount} renders failed: Studio viewport too small`
			)
		elseif failCount > 0 then
			addToast(
				"error",
				`{failCount} render{if failCount == 1 then "" else "s"} failed: Studio viewport too small`
			)
		end
	end)
end

return function(
	state: Store.AppState,
	dispatch: (any) -> (),
	renderingRef: { current: boolean },
	animationPlayingRef: { current: boolean },
	addToast: ToastFn
)
	-- Builds a targets list and starts a render batch.
	-- When `indices` is provided only those model indices are rendered; otherwise all non-exported models are rendered.
	local function startRender(indices: { number }?)
		if renderingRef.current then return end
		local targets = {}
		if indices then
			for _, idx in ipairs(indices) do
				local entry = state.models[idx]
				if entry and not entry.isExported then
					table.insert(targets, { index = idx, entry = entry })
				end
			end
		else
			for i, entry in ipairs(state.models) do
				if not entry.isExported then
					table.insert(targets, { index = i, entry = entry })
				end
			end
		end
		if #targets == 0 then return end
		renderingRef.current = true
		dispatch({ type = Store.ACTIONS.SET_RENDERING, rendering = true, progress = 0, total = #targets })
		runRenderBatch(targets, dispatch, buildRenderSettings(state), addToast, animationPlayingRef, renderingRef)
	end

	local function startRenderSelected()
		startRender(state.selectedModelIndices)
	end

	local function startRenderAll()
		startRender()
	end

	local function rerenderPreview()
		if renderingRef.current then return end
		local idx = state.previewModelIndex
		if not idx then return end
		local entry = state.models[idx]
		if not entry or entry.isExported then return end

		renderingRef.current = true
		dispatch({ type = Store.ACTIONS.SET_RENDERING, rendering = true, progress = 0, total = 1 })
		dispatch({ type = Store.ACTIONS.SET_RENDER_STATUS, index = idx, status = "pending" })

		task.spawn(function()
			local ok, img = renderOne(entry.instance, buildRenderSettings(state)):await()
			dispatch({
				type = Store.ACTIONS.SET_RENDER_STATUS,
				index = idx,
				status = if ok then "ok" else "fail",
				image = if ok then img else nil,
			})
			dispatch({ type = Store.ACTIONS.SET_RENDERING, rendering = false, progress = 0, total = 0 })
			renderingRef.current = false
			if ok and img then
				dispatch({
					type = Store.ACTIONS.SET_PREVIEW_IMAGE,
					image = img,
					title = entry.instance.Name,
					index = idx,
				})
			else
				addToast("error", "Render failed: Studio viewport too small")
			end
		end)
	end

	return {
		startRenderSelected = startRenderSelected,
		startRenderAll = startRenderAll,
		rerenderPreview = rerenderPreview,
	}
end

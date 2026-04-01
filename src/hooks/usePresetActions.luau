local Store = require(script.Parent.Parent.Store)

return function(
	state: Store.AppState,
	dispatch: (any) -> ()
)
	local function openSaveModal()
		dispatch({ type = Store.ACTIONS.SET_NAME_INPUT_MODAL, value = { mode = "save" } })
	end

	local function openRenameModal(index: number)
		local preset = state.presets[index]
		if not preset then return end
		dispatch({
			type = Store.ACTIONS.SET_NAME_INPUT_MODAL,
			value = { mode = "rename", targetIndex = index, initialName = preset.name },
		})
	end

	local function closeNameInputModal()
		dispatch({ type = Store.ACTIONS.SET_NAME_INPUT_MODAL, value = nil })
	end

	local function confirmNameInput(name: string)
		local modal = state.nameInputModal
		if not modal then return end
		local next = table.clone(state.presets)
		if modal.mode == "save" then
			table.insert(next, {
				name = name,
				yaw = state.yaw,
				pitch = state.pitch,
				roll = state.roll,
				fov = state.fov,
				cameraDistance = state.cameraDistance,
				cameraOffsetX = state.cameraOffsetX,
				cameraOffsetY = state.cameraOffsetY,
				cameraOffsetZ = state.cameraOffsetZ,
				bgMode = state.bgMode,
				bgColor = state.bgColor,
				exportSize = state.exportSize,
				outline = state.outline,
				dropShadow = state.dropShadow,
				innerShadow = state.innerShadow,
				outerGlow = state.outerGlow,
				chromaticAberration = state.chromaticAberration,
				lighting = state.lighting,
			})
		elseif modal.mode == "rename" and modal.targetIndex then
			local entry = table.clone(next[modal.targetIndex])
			entry.name = name
			next[modal.targetIndex] = entry
		end
		dispatch({ type = Store.ACTIONS.SET_PRESETS, value = next })
	end

	local function applyPreset(index: number)
		local preset = state.presets[index]
		if not preset then return end
		dispatch({ type = Store.ACTIONS.APPLY_PRESET, value = preset })
	end

	local function confirmDeletePreset(index: number)
		local next = table.clone(state.presets)
		table.remove(next, index)
		dispatch({ type = Store.ACTIONS.SET_PRESETS, value = next })
	end

	return {
		openSaveModal = openSaveModal,
		openRenameModal = openRenameModal,
		closeNameInputModal = closeNameInputModal,
		confirmNameInput = confirmNameInput,
		applyPreset = applyPreset,
		confirmDeletePreset = confirmDeletePreset,
	}
end

local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local Selection = game:GetService("Selection")
local Store = require(script.Parent.Parent.Store)
local exportAll = require(script.Parent.Parent.lib.exportAll)

type ToastFn = (string, string) -> ()

return function(
	state: Store.AppState,
	addToast: ToastFn
)
	local function doExport()
		local parts = exportAll(state.models)
		if #parts > 0 then
			pcall(function()
				Selection:Set(parts)
			end)
			addToast("normal", `Exported {#parts} model{if #parts == 1 then "" else "s"} to Workspace`)
		end
	end

	local function exportPreviewImage()
		if not state.previewImage then return end
		local tempEntry = {
			instance = { Name = state.previewTitle or "Render" },
			image = state.previewImage,
			status = "ok" :: Store.RenderStatus,
			isExported = false,
		}
		local parts = exportAll({ tempEntry })
		if #parts > 0 then
			pcall(function()
				Selection:Set(parts)
			end)
		end
	end

	return {
		doExport = doExport,
		exportPreviewImage = exportPreviewImage,
	}
end

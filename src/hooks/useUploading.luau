local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local Store = require(script.Parent.Parent.Store)
local Types = require(script.Parent.Parent.Types)
local uploadOne = require(script.Parent.Parent.lib.uploadOne)

type UploadResult = Types.UploadResult

return function(
	state: Store.AppState,
	uploadingRef: { current: boolean }
)
	local uploading, setUploading = React.useState(false)
	local uploadProgress, setUploadProgress = React.useState(0)
	local uploadTotal, setUploadTotal = React.useState(0)
	local uploadResults, setUploadResults = React.useState(nil :: { UploadResult }?)

	local function uploadPreviewImage()
		if uploadingRef.current or not state.previewImage then return end
		uploadingRef.current = true
		setUploading(true)
		setUploadTotal(1)
		setUploadProgress(0)
		task.spawn(function()
			local ok, assetId = uploadOne(state.previewImage :: EditableImage, state.previewTitle or "Render")
			uploadingRef.current = false
			setUploading(false)
			setUploadTotal(0)
			setUploadProgress(0)
			setUploadResults({ { name = state.previewTitle or "Render", assetId = if ok then assetId else nil } })
		end)
	end

	local function doUploadAll()
		if uploadingRef.current then return end
		local targets = {}
		for _, entry in ipairs(state.models) do
			if entry.image then
				table.insert(targets, entry)
			end
		end
		if #targets == 0 then return end
		uploadingRef.current = true
		setUploading(true)
		setUploadProgress(0)
		setUploadTotal(#targets)
		task.spawn(function()
			local results: { UploadResult } = {}
			for i, entry in ipairs(targets) do
				setUploadProgress(i - 1)
				local ok, assetId = uploadOne(entry.image :: EditableImage, entry.instance.Name)
				table.insert(results, { name = entry.instance.Name, assetId = if ok then assetId else nil })
				setUploadProgress(i)
			end
			uploadingRef.current = false
			setUploading(false)
			setUploadTotal(0)
			setUploadProgress(0)
			setUploadResults(results)
		end)
	end

	return {
		uploading = uploading,
		uploadProgress = uploadProgress,
		uploadTotal = uploadTotal,
		uploadResults = uploadResults,
		setUploadResults = setUploadResults,
		doUploadAll = doUploadAll,
		uploadPreviewImage = uploadPreviewImage,
	}
end

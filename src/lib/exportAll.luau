local CollectionService = game:GetService("CollectionService")
local Types = require(script.Parent.Parent.Types)
local Constants = require(script.Parent.Parent.Constants)

local MPB_TAG = Constants.MPB_TAG

local function getOrCreateFolder(): Folder
	local folder = workspace:FindFirstChild(Constants.EXPORT_FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = Constants.EXPORT_FOLDER_NAME
		folder.Parent = workspace
	end
	return folder :: Folder
end

-- Creates a MeshPart icon for a single entry. Returns the part on success, nil on failure.
local function exportEntry(entry: Types.ModelEntry, folder: Folder, n: number): MeshPart?
	local part = nil
	pcall(function()
		local existing = folder:FindFirstChild(entry.instance.Name .. "_Icon")
		if existing then
			existing:Destroy()
		end
		local p = Instance.new("MeshPart")
		p.Name = entry.instance.Name .. "_Icon"
		p.Size = Constants.EXPORT_MESH_SIZE
		p.Anchored = true
		p.CastShadow = false
		p.Position = Vector3.new(n * Constants.EXPORT_SPACING, 10, 0)
		p.TextureContent = Content.fromObject(entry.image)
		CollectionService:AddTag(p, MPB_TAG)
		p:SetAttribute("MPBSourceName", entry.instance.Name)
		p.Parent = folder
		part = p
	end)
	return part
end

local function exportAll(models: { Types.ModelEntry }): { Instance }
	local folder = getOrCreateFolder()
	local exportedParts = {}
	local n = 0
	for _, entry in ipairs(models) do
		if entry.image then
			local part = exportEntry(entry, folder, n)
			if part then
				n += 1
				table.insert(exportedParts, part)
			end
		end
	end
	return exportedParts
end

local function exportSelected(models: { Types.ModelEntry }, selectedIndices: { number }): { Instance }
	local folder = getOrCreateFolder()
	local indexSet = {}
	for _, idx in ipairs(selectedIndices) do
		indexSet[idx] = true
	end
	local exportedParts = {}
	local n = 0
	for i, entry in ipairs(models) do
		if indexSet[i] and entry.image then
			local part = exportEntry(entry, folder, n)
			if part then
				n += 1
				table.insert(exportedParts, part)
			end
		end
	end
	return exportedParts
end

return {
	exportAll = exportAll,
	exportSelected = exportSelected,
}

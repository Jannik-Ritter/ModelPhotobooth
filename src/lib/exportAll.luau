local CollectionService = game:GetService("CollectionService")

local MPB_TAG = "_MPBIcon"
local EXPORT_FOLDER = "PhotoboothExports"

type ModelEntry = {
	instance: Instance,
	image: EditableImage?,
	[string]: any,
}

local function exportAll(models: { ModelEntry }): { Instance }
	local folder = workspace:FindFirstChild(EXPORT_FOLDER)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = EXPORT_FOLDER
		folder.Parent = workspace
	end

	local exportedParts = {}
	local n = 0

	for _, entry in ipairs(models) do
		if entry.image then
			local part = nil
			pcall(function()
				local existing = folder:FindFirstChild(entry.instance.Name .. "_Icon")
				if existing then
					existing:Destroy()
				end
				local p = Instance.new("MeshPart")
				p.Name = entry.instance.Name .. "_Icon"
				p.Size = Vector3.new(4, 4, 0.05)
				p.Anchored = true
				p.CastShadow = false
				p.Position = Vector3.new(n * 5, 10, 0)
				p.TextureContent = Content.fromObject(entry.image)
				CollectionService:AddTag(p, MPB_TAG)
				p:SetAttribute("MPBSourceName", entry.instance.Name)
				p.Parent = folder
				part = p
			end)
			if part then
				n += 1
				table.insert(exportedParts, part)
			end
		end
	end

	return exportedParts
end

return exportAll

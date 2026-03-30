local AssetService = game:GetService("AssetService")

local function uploadOne(image: EditableImage, name: string): (boolean, number?)
	local ok, resultOrErr = pcall(function()
		local result, assetId = AssetService:CreateAssetAsync(
			image,
			Enum.AssetType.Image,
			{ Name = name }
		)
		if result == Enum.CreateAssetResult.Success then
			return assetId
		end
		error(tostring(result))
	end)
	if ok then
		return true, resultOrErr
	end
	return false, nil
end

return uploadOne

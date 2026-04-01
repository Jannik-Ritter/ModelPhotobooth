local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local Selection = game:GetService("Selection")
local CollectionService = game:GetService("CollectionService")
local Store = require(script.Parent.Parent.Store)
local Constants = require(script.Parent.Parent.Constants)

local MPB_TAG = Constants.MPB_TAG

return function(dispatch: (any) -> (), modelsRef: { current: { Store.ModelEntry } })
	React.useEffect(function()
		local function refresh()
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
						status = "ok" :: Store.RenderStatus,
						image = nil,
						isExported = true,
					})
				elseif obj:IsA("Model") or obj:IsA("BasePart") then
					local prev = existing[obj]
					table.insert(models, {
						instance = obj,
						status = if prev then prev.status else "idle" :: Store.RenderStatus,
						image = if prev then prev.image else nil,
						isExported = false,
					})
				end
			end
			dispatch({ type = Store.ACTIONS.SET_MODELS, value = models })
			dispatch({
				type = Store.ACTIONS.SET_SELECTION,
				value = if #models > 0 then { 1 } else {},
			})
		end
		local conn = Selection.SelectionChanged:Connect(refresh)
		refresh()
		return function()
			conn:Disconnect()
		end
	end, {} :: { any })
end

local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local Store = require(script.Parent.Parent.Store)
local PresetSerialization = require(script.Parent.Parent.lib.presetSerialization)

return function(
	dispatch: (any) -> (),
	presets: { Store.PresetEntry },
	plugin: any
)
	React.useEffect(function()
		local raw = plugin:GetSetting("presets")
		if type(raw) == "table" then
			local ok, result = pcall(PresetSerialization.deserialize, raw)
			if ok then
				dispatch({ type = Store.ACTIONS.SET_PRESETS, value = result })
			end
		end
	end, {} :: { any })

	React.useEffect(function()
		plugin:SetSetting("presets", PresetSerialization.serialize(presets))
	end, { presets } :: { any })
end

local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local Store = require(script.Parent.Parent.Store)

return function(
	dispatch: (any) -> (),
	activeInstance: Instance?,
	animationPlayingRef: { current: boolean },
	activeAnimationIndexRef: { current: number? }
)
	React.useEffect(function()
		if not activeInstance then
			dispatch({ type = Store.ACTIONS.SET_ANIMATIONS, value = {} })
			return
		end
		local anims: { Store.AnimationInfo } = {}
		for _, desc in ipairs(activeInstance:GetDescendants()) do
			if desc:IsA("Animation") and desc.AnimationId ~= "" then
				table.insert(anims, {
					name = desc.Name,
					animationId = desc.AnimationId,
				})
			end
		end
		dispatch({ type = Store.ACTIONS.SET_ANIMATIONS, value = anims })
	end, { activeInstance } :: { any })

end

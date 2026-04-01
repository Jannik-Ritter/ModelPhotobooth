local Packages = script.Parent.Parent.Packages
local React = require(Packages.react)
local Store = require(script.Parent.Store)

export type StoreContextValue = {
	state: Store.AppState,
	dispatch: (any) -> (),
}

local context = React.createContext(nil :: StoreContextValue?)

local function useStore(): StoreContextValue
	local ctx = React.useContext(context)
	assert(ctx ~= nil, "useStore() must be called within StoreContext.Provider")

	return ctx
end

context.useStore = useStore

return context

-- Unique sentinel: pass as a value in the overrides table to explicitly clear a key to nil.
-- Needed because pairs() silently skips nil values, so { key = nil } would never overwrite anything.
local CLEAR = {}

local function merge(base: { [any]: any }, overrides: { [any]: any }): { [any]: any }
	local result = table.clone(base)
	for k, v in pairs(overrides) do
		result[k] = if v == CLEAR then nil else v
	end
	return result
end

return { merge = merge, CLEAR = CLEAR }

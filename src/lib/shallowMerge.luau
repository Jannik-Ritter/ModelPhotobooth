return function(base: { [any]: any }, overrides: { [any]: any }): { [any]: any }
	local result = table.clone(base)
	for k, v in pairs(overrides) do
		result[k] = v
	end
	return result
end

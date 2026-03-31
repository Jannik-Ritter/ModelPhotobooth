local function limitDecimals(value: number, decimals: number): string
	if value == -0 then
		value = 0
	end

	local text = string.format("%." .. decimals .. "f", value)
	text = text:gsub("(%..-)0+$", "%1")
	text = text:gsub("%.$", "")

	return text
end

return limitDecimals

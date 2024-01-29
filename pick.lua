local function pick(values)
	if type(values) ~= "table" then return values, 0 end
	if #values == 0 then return nil, 0 end
	if #values == 1 then return values[1], 1 end
	local i = 0
	while i < 1 or i > #values do
		i = math.random(#values)
	end
	return values[i], i
end

return pick

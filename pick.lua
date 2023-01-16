local function pick(t)
	if type(t) ~= "table" then return t end
	if #t == 0 then return end
	if #t == 1 then return t[1] end
	local i = 0
	while i < 1 or i > #t do
		i = math.random(#t)
	end
	return t[i], i
end

return pick

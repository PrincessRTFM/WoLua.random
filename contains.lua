local function contains(list, element)
	for _, value in pairs(list) do
		if value == element then
			return true
		end
	end
	return false
end

return contains

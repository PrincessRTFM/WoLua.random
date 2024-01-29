---Check if a table contains a given element
---@param list table The list of values to search
---@param element any The value to look for
---@return boolean found Whether or not the given value was found
local function contains(list, element)
	for _, value in pairs(list) do
		if value == element then
			return true
		end
	end
	return false
end

return contains

---Take a single word off a string, optionally transforming it, and return the word and the remaining text, both trimmed of whitespace
---@param text any
---@param wordTransformer? function
---@return string word The first word of the text
---@return string remainder The remaining text
local function shiftWord(text, wordTransformer)
	if type(text) ~= "string" then text = tostring(text) end
	local word, rest = text:match("([%w-]+)(.*)")
	word = (word or ""):match("^%s*(.-)%s*$")
	rest = (rest or ""):match("^%s*(.-)%s*$")
	if type(wordTransformer) == "function" then word = wordTransformer(word) end
	return word, rest
end

return shiftWord

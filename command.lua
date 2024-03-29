--Script.Debug.Enabled = true

local pick = require "pick"
local contains = require "contains"
local shiftWord = require "shiftWord"

-- all of the script commands can have aliases, but the FIRST one is the one listed in the help command's output

CmdHelp = { "help", "?", "" }
CmdList = { "list", "show", "ls" }
CmdAdd = { "add", "new" }
CmdRemove = { "del", "delete", "rm", "remove" }
CmdClear = { "clear", "empty" }
CmdCopy = { "copy", "clone", "cp" }
CmdRename = { "move", "rename", "mv" }
CmdDelete = { "delete-list", "deletelist" }
CmdPick = { "echo", "pick", "get" }
CmdExecute = { "execute", "exec", "call", "run", "do" }
CmdEvaluate = { "evaluate", "eval" }
CmdConfig = { "config", "configure", "setting" }
CmdExport = { "export" }
CmdImport = { "import" }
CmdInspect = { "debug", "inspect" }

-- these are used by the configuration command for boolean settings
ValueTrue = { "true", "on", "yes", "enable", "enabled" }
ValueFalse = { "false", "off", "no", "disable", "disabled" }
ValueToggle = { "toggle", "flip", "invert", "" }

-- all changes are live to the persistent storage table, and every change also saves the storage to disk
-- it COULD be done with a cache, but then users would need to remember to run a save command, and I don't trust them
Script.Storage.lists = type(Script.Storage.lists) == "table" and Script.Storage.lists or {}
Script.Storage.config = type(Script.Storage.config) == "table" and Script.Storage.config or {}
Script.Storage.config.SuppressWarnings = Script.Storage.config.SuppressWarnings or false
Script.Storage.config.SuppressStatusMessages = Script.Storage.config.SuppressStatusMessages or false
Script.Storage.config.VerboseSelection = Script.Storage.config.VerboseSelection or false
Script.Storage.config.SilentExecution = Script.Storage.config.SilentExecution or false
Script.Storage.config.AllowRawChatInput = Script.Storage.config.AllowRawChatInput or false
--Script.Debug.DumpStorage()
Script.SaveStorage()

-- this is called before the plugin even tries to handle the command provided, in order to remove any invalid entries
-- if we manage to get something invalid in the list table, then half the actual commands would break on it, so rather
-- than duplicating code to skip such issues, we just strip any problems out from the start
local function CleanStorage()
	local lists = Script.Storage.lists;
	local cleaned = false
	for k, v in pairs(lists) do
		if type(v) ~= "table" then
			print(string.format("Deleting broken list %s (%s)", k, type(v)))
			lists[k] = nil
			cleaned = true
		end
	end
	if cleaned then
		print("Saving cleaned storage")
		Script.SaveStorage()
	end
end
local function Help()
	local cmd = Script.CallSelfCommand
	Game.PrintMessage(
		string.format(
			"%s %s - display all lists",
			cmd,
			CmdList[1]
		)
	)
	Game.PrintMessage(
		string.format(
			"%s %s <listName> - display contents of named list",
			cmd,
			CmdList[1]
		)
	)
	Game.PrintMessage(
		string.format(
			"%s %s <listName> <contents to add...> - add the given contents as a new item on the named list",
			cmd,
			CmdAdd[1]
		)
	)
	Game.PrintMessage(
		string.format(
			"%s %s <listName> [<index>] - remove the item at the given index from the named list; if no index is given, the LAST item is removed",
			cmd,
			CmdRemove[1]
		)
	)
	Game.PrintMessage(
		string.format(
			"%s %s <listName> - remove all items in the named list",
			cmd,
			CmdClear[1]
		)
	)
	Game.PrintMessage(
		string.format(
			"%s %s <listName> <newName> - clone the named list under a new name",
			cmd,
			CmdCopy[1]
		)
	)
	Game.PrintMessage(
		string.format(
			"%s %s <listName> <newName> - move the named list to a new name",
			cmd,
			CmdRename[1]
		)
	)
	Game.PrintMessage(
		string.format(
			"%s %s <listName> - delete the named list",
			cmd,
			CmdDelete[1]
		)
	)
	Game.PrintMessage(
		string.format(
			"%s %s <listName> - pick a random item from the named list and echo it",
			cmd,
			CmdPick[1]
		)
	)
	Game.PrintMessage(
		string.format(
			"%s %s <listName> - pick a random item from the named list and run it as a chat command",
			cmd,
			CmdExecute[1]
		)
	)
	Game.PrintMessage(
		string.format(
			"%s %s <listName> <input line...> - pick a random item from the named list and run the given input line, replacing all instances of \"$$$\" with the chosen item",
			cmd,
			CmdEvaluate[1]
		)
	)
	--[[ TODO: document script config settings
	Game.PrintMessage(
		string.format(
			"%s %s <setting> <value...> - change one of the script's config settings",
			cmd,
			CmdConfig[1]
		)
	)]]
	Game.PrintMessage(
		string.format(
			"%s %s <listName> - serialise the named list to a JSON array and put it into the system clipboard",
			cmd,
			CmdExport[1]
		)
	)
	Game.PrintMessage(
		string.format(
			"%s %s <listName> - try to parse the system clipboard's contents as a JSON array; if successful, save them as the named list",
			cmd,
			CmdImport[1]
		)
	)
	Game.PrintMessage("List names are case-sensitive, commands are not.")
end
local function ListNames()
	local found = 0
	local msg = ""
	for name, list in pairs(Script.Storage.lists) do
		found = found + 1
		msg = msg .. string.format(", %s (%d entr%s)", name, #list, #list == 1 and "y" or "ies")
	end
	if found == 0 then
		if not Script.Storage.config.SuppressWarnings then
			Game.PrintError("No saved lists found")
		end
		return
	end
	Game.PrintMessage(string.format("%d list%s: ", found, found ~= 1 and "s" or "") .. msg:sub(3))
end
local function DisplayContents(args)
	local target = shiftWord(args)
	local list = Script.Storage.lists[target]
	if type(list) ~= "table" then
		Game.PrintError(string.format("No such list [%s]", target))
		return
	end
	if #list == 0 then
		Game.PrintMessage(string.format("List [%s] is empty", target))
		return
	end
	local msg = string.format("List [%s] has %d entr%s:", target, #list, #list == 1 and "y" or "ies")
	local width = string.len(#list)
	for i, v in ipairs(list) do
		msg = msg .. string.format("\n%0" .. width .. "d: %s", i, v)
	end
	Game.PrintMessage(msg)
end
local function AddItem(args)
	local target, content = shiftWord(args)
	if #target < 1 then
		Game.PrintError("No list name specified")
		return
	end
	local list = Script.Storage.lists[target] or {}
	table.insert(list, content)
	Script.Storage.lists[target] = list
	if Script.SaveStorage() and not Script.Storage.config.SuppressStatusMessages then
		Game.PrintMessage(string.format("Added new item #%d [%s] to list [%s]", #list, content, target))
	end
end
local function RemoveItem(args)
	-- We have to use an index here because we can't guarantee that remove-by-element will get the right one
	---@type string
	local target
	---@type string|number?
	local idx
	target, idx = shiftWord(args)
	if #target < 1 then
		Game.PrintError("No list name specified")
		return
	end
	local list = Script.Storage.lists[target]
	if type(list) ~= "table" then
		Game.PrintError(string.format("No such list [%s]", target))
		return
	end
	if idx == "" then
		idx = #list
	end
	idx = tonumber(idx)
	if type(idx) == "number" then
		idx = math.floor(idx)
	end
	if type(idx) ~= "number" or idx < 1 or idx > #list then
		Game.PrintError(string.format("Invalid index [%s] - must be a number between [1] and [%d] (inclusive)", tostring(idx), #list))
		return
	end
	local pulled = table.remove(list, idx)
	Script.Storage.lists[target] = list
	if Script.SaveStorage() and not Script.Storage.config.SuppressStatusMessages then
		Game.PrintMessage(string.format("Removed item %d [%s] from list [%s]", idx, pulled, target))
	end
end
local function ClearList(args)
	local target = shiftWord(args)
	if #target < 1 then
		Game.PrintError("No list name specified")
		return
	end
	Script.Storage.lists[target] = {}
	if Script.SaveStorage() and not Script.Storage.config.SuppressStatusMessages then
		Game.PrintMessage(string.format("Cleared list [%s]", target))
	end
end
local function DeleteList(args)
	local target = shiftWord(args)
	if #target < 1 then
		Game.PrintError("No list name specified")
		return
	end
	Script.Storage.lists[target] = nil
	if Script.SaveStorage() and not Script.Storage.config.SuppressStatusMessages then
		Game.PrintMessage(string.format("Deleted list [%s]", target))
	end
end
local function CopyList(args)
	local source, dest
	source, args = shiftWord(args)
	dest = shiftWord(args)
	if type(Script.Storage.lists[source]) ~= "table" then
		Game.PrintError(string.format("Cannot rename non-existent list [%s]", source))
		return
	end
	if type(Script.Storage.lists[dest]) == "table" then
		Game.PrintError(string.format("Cannot overwrite existing list [%s]", dest))
		return
	end
	local origin = Script.Storage.lists[source]
	local clone = {}
	for i, v in ipairs(origin) do
		clone[i] = v
	end
	Script.Storage.lists[dest] = clone
	if Script.SaveStorage() and not Script.Storage.config.SuppressStatusMessages then
		Game.PrintMessage(string.format("Copied list [%s] into new slot [%s]", source, dest))
	end
end
local function RenameList(args)
	local source, dest
	source, args = shiftWord(args)
	dest = shiftWord(args)
	if type(Script.Storage.lists[source]) ~= "table" then
		Game.PrintError(string.format("Cannot rename non-existent list [%s]", source))
		return
	end
	if type(Script.Storage.lists[dest]) == "table" then
		Game.PrintError(string.format("Cannot overwrite existing list [%s]", dest))
		return
	end
	Script.Storage.lists[dest] = Script.Storage.lists[source]
	Script.Storage.lists[source] = nil
	if Script.SaveStorage() and not Script.Storage.config.SuppressStatusMessages then
		Game.PrintMessage(string.format("Renamed list [%s] into new slot [%s]", source, dest))
	end
end
local function EchoItem(args)
	local target = shiftWord(args)
	if #target < 1 then
		Game.PrintError("No list name specified")
		return
	end
	local list = Script.Storage.lists[target]
	if type(list) ~= "table" then
		Game.PrintError(string.format("No such list [%s]", target))
		return
	end
	if #list == 0 then
		if not Script.Storage.config.SuppressWarnings then
			Game.PrintError(string.format("No entries in list [%s]", target))
		end
		return
	end
	local item, index = pick(list)
	if Script.Storage.config.VerboseSelection then
		Game.PrintMessage(string.format("Selected #%d from [%s]:\n%s", index, target, item))
	else
		Game.PrintMessage(string.format("%d: %s", index, item))
	end
end
local function ExecuteItem(args)
	local target = shiftWord(args)
	if #target < 1 then
		Game.PrintError("No list name specified")
		return
	end
	local list = Script.Storage.lists[target]
	if type(list) ~= "table" then
		Game.PrintError(string.format("No such list [%s]", target))
		return
	end
	if #list == 0 then
		if not Script.Storage.config.SuppressWarnings then
			Game.PrintError(string.format("No entries in list [%s]", target))
		end
		return
	end
	local item, index = pick(list)
	local refused = item:sub(1, 1) ~= "/" and not Script.Storage.config.AllowRawChatInput
	if refused or not Script.Storage.config.SilentExecution then
		local output = refused and Game.PrintError or Game.PrintMessage
		output(string.format("%d: %s", index, item))
	end
	if refused then
		Game.PrintError("You must enable AllowRawChatInput to \"execute\" text that does not begin with a slash")
		return
	end
	Game.SendChat(item)
end
local function EvaluateItem(args)
	local target, chatline = shiftWord(args)
	if #target < 1 then
		Game.PrintError("No list name specified")
		return
	end
	local list = Script.Storage.lists[target]
	if type(list) ~= "table" then
		Game.PrintError(string.format("No such list [%s]", target))
		return
	end
	if #list == 0 then
		if not Script.Storage.config.SuppressWarnings then
			Game.PrintError(string.format("No entries in list [%s]", target))
		end
		return
	end
	local item, index = pick(list)
	local toRun = string.gsub(chatline, "%$%$%$", item)
	if toRun == chatline then -- This is /probably/ user error
		Game.PrintError(string.format("No replacement token (\"$$$\") was found in your evaluation text [%s]", chatline))
		Game.PrintError("Since this is almost certainly a mistake, no chat will be entered")
		return
	end
	local refused = toRun:sub(1, 1) ~= "/" and not Script.Storage.config.AllowRawChatInput
	if refused or not Script.Storage.config.SilentExecution then
		local output = refused and Game.PrintError or Game.PrintMessage
		output(string.format("%d: %s\n%s", index, item, toRun))
	end
	if refused then
		Game.PrintError("You must enable AllowRawChatInput to \"execute\" text that does not begin with a slash")
		return
	end
	Game.SendChat(toRun)
end
local function Configure(args)
	local target, value = shiftWord(args)
	if #target < 1 then
		Game.PrintError("No configuration setting specified")
		return
	end
	local cfg = Script.Storage.config
	local typ = type(cfg[target])
	if typ == "boolean" then
		if contains(ValueTrue, value) then
			cfg[target] = true
		elseif contains(ValueFalse, value) then
			cfg[target] = false
		elseif contains(ValueToggle, value) then
			cfg[target] = not cfg[target]
		else
			Game.PrintError(string.format("Unknown boolean state [%s]", value))
			return
		end
	else
		Game.PrintError(string.format("Unknown setting [%s] (case-sensitive)", target))
		return
	end
	Script.Storage.config = cfg
	if Script.SaveStorage() then
		Game.PrintMessage(string.format("%s is now %s", target, tostring(cfg[target])))
	end
end
local function ExportList(args)
	local target = shiftWord(args)
	if #target < 1 then
		Game.PrintError("No list name specified")
		return
	end
	local list = Script.Storage.lists[target]
	if type(list) ~= "table" then
		Game.PrintError(string.format("No such list [%s]", target))
		return
	end
	if #list == 0 then
		Game.PrintError(string.format("List [%s] is empty", target))
		return
	end
	local str = Script.SerialiseJson(list)
	if str == nil then
		Game.PrintError(string.format("Failed to serialise list [%s] to JSON", target))
		return
	end
	Script.Clipboard = str
	if not Script.Storage.config.SuppressStatusMessages then
		Game.PrintMessage(string.format("Serialised %d entr%s from list [%s] to clipboard", #list, #list == 1 and "y" or "ies", target))
	end
end
local function ImportList(args)
	local target = shiftWord(args)
	if #target < 1 then
		Game.PrintError("No list name specified")
		return
	end
	if type(Script.Storage.lists[target]) == "table" then
		Game.PrintError(string.format("Cannot overwrite existing list [%s]", target))
		return
	end
	local parsed = Script.ParseJson(Script.Clipboard)
	if parsed == nil then
		Game.PrintError("Clipboard does not appear to contain a valid lua table")
		return
	end
	local list = {}
	local idx = 0
	for _ in pairs(parsed) do
		idx = idx + 1
		if parsed[idx] == nil then
			Game.PrintError("Clipboard JSON seems to be an object, not an array")
			return
		end
		list[idx] = tostring(parsed[idx])
	end
	Script.Storage.lists[target] = list
	if Script.SaveStorage() and not Script.Storage.config.SuppressStatusMessages then
		Game.PrintMessage(string.format("Deserialised %d entr%s from clipboard into new list [%s]", idx, idx == 1 and "y" or "ies", target))
	end
end

-- this is an unlisted debugging command, which doesn't require the script to be in debug mode but DOES require you to know it exists
local function Inspect(args)
	local target = shiftWord(args)
	if #target < 1 then
		Game.PrintError("Nothing to debug inspect")
		return
	end
	local thing = Script.Storage.lists[target]
	Game.PrintMessage(string.format("Storage.lists.%s: %s", target, type(thing)))
	if type(thing) == "table" then
		Game.PrintMessage(Script.SerialiseJson(thing))
	else
		Game.PrintMessage(tostring(thing))
	end
end

-- this is basically just a function to dispatch the ACTUAL handler function
local function core(textline)
	CleanStorage()
	local action, args = shiftWord(textline, string.lower)
	if contains(CmdHelp, action) then
		Help()
	elseif contains(CmdList, action) then
		if #args > 0 then -- displaying the contents of a named list (with indexes)
			DisplayContents(args)
		else -- displaying all known list names (with the number of entries)
			ListNames()
		end
	elseif contains(CmdAdd, action) then
		AddItem(args)
	elseif contains(CmdRemove, action) then
		RemoveItem(args)
	elseif contains(CmdClear, action) then
		ClearList(args)
	elseif contains(CmdDelete, action) then
		DeleteList(args)
	elseif contains(CmdCopy, action) then
		CopyList(args)
	elseif contains(CmdRename, action) then
		RenameList(args)
	elseif contains(CmdPick, action) then
		EchoItem(args)
	elseif contains(CmdExecute, action) then
		ExecuteItem(args)
	elseif contains(CmdEvaluate, action) then
		EvaluateItem(args)
	elseif contains(CmdConfig, action) then
		Configure(args)
	elseif contains(CmdExport, action) then
		ExportList(args)
	elseif contains(CmdImport, action) then
		ImportList(args)
	elseif contains(CmdInspect, action) then
		Inspect(args)
	else
		Game.PrintMessage(string.format("Unknown command [%s]", action))
		Game.PrintMessage(string.format("Use [%s %s %s] for command help", Script.PluginCommand, Script.Name, CmdHelp[1]))
	end
end

Script(core)

Script.Debug.Enabled = true

local pick = require 'pick'
local contains = require 'contains'
local shiftWord = require 'shiftWord'

cmdHelp = { "help", "?", "" }
cmdList = { "list", "show", "ls" }
cmdAdd = { "add", "new" }
cmdRemove = { "del", "delete", "rm", "remove" }
cmdClear = { "clear", "empty" }
cmdDelete = { "delete-list", "deletelist" }
cmdRename = { "move", "rename", "mv" }
cmdPick = { "echo", "pick", "get" }
cmdExecute = { "execute", "exec", "call", "run", "do" }
cmdEvaluate = { "evaluate", "eval" }
cmdConfig = { "config", "setting" }

valueTrue = { "true", "on", "yes", "enable", "enabled" }
valueFalse = { "false", "off", "no", "disable", "disabled" }
valueToggle = { "toggle", "flip", "invert", "" }

Script.Storage.lists = type(Script.Storage.lists) == "table" and Script.Storage.lists or {}
Script.Storage.config = type(Script.Storage.config) == "table" and Script.Storage.config or {}
Script.Storage.config.SuppressWarnings = Script.Storage.config.SuppressWarnings or false
Script.Storage.config.SuppressStatusMessages = Script.Storage.config.SuppressStatusMessages or false
Script.Storage.config.VerboseSelection = Script.Storage.config.VerboseSelection or false
Script.Storage.config.SilentExecution = Script.Storage.config.SilentExecution or false
Script.Storage.config.AllowRawChatInput = Script.Storage.config.AllowRawChatInput or false
Script.Debug.DumpStorage()

local function Help()
	local cmd = Script.CallSelfCommand
	Game.PrintMessage(
		string.format(
			"%s %s - display all lists",
			cmd,
			cmdList[1]
		)
	)
	Game.PrintMessage(
		string.format(
			"%s %s <listName> - display contents of named list",
			cmd,
			cmdList[1]
		)
	)
	Game.PrintMessage(
		string.format(
			"%s %s <listName> <contents to add...> - add the given contents as a new item on the named list",
			cmd,
			cmdAdd[1]
		)
	)
	Game.PrintMessage(
		string.format(
			"%s %s <listName> [<index>] - remove the item at the given index from the named list; if no index is given, the LAST item is removed",
			cmd,
			cmdRemove[1]
		)
	)
	Game.PrintMessage(
		string.format(
			"%s %s <listName> - remove all items in the named list",
			cmd,
			cmdClear[1]
		)
	)
	Game.PrintMessage(
		string.format(
			"%s %s <listName> - delete the named list",
			cmd,
			cmdDelete[1]
		)
	)
	Game.PrintMessage(
		string.format(
			"%s %s <listName> - pick a random item from the named list and echo it",
			cmd,
			cmdPick[1]
		)
	)
	Game.PrintMessage(
		string.format(
			"%s %s <listName> - pick a random item from the named list and run it as a chat command",
			cmd,
			cmdExecute[1]
		)
	)
	Game.PrintMessage(
		string.format(
			"%s %s <listName> <input line...> - pick a random item from the named list and run the given input line, replacing all instances of \"$$$\" with the chosen item",
			cmd,
			cmdEvaluate[1]
		)
	)
	Game.PrintMessage("List names are case-sensitive, commands are not.")
end
local function ListNames()
	local found = 0
	local msg = ""
	for name,list in pairs(Script.Storage.lists) do
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
	local msg = string.format("List %s: %d entr%s", target, #list, #list == 1 and "y" or "ies")
	local width = string.len(#list)
	for i,v in ipairs(list) do
		msg = msg .. string.format("\n%0" .. width .. "d: %s", i, v)
	end
	Game.PrintMessage(msg)
end
local function AddItem(args)
	local target, content = shiftWord(args)
	if not target then
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
	local target, idx = shiftWord(args)
	if not target then
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
	idx = math.floor(tonumber(idx))
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
	if not target then
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
	if not target then
		Game.PrintError("No list name specified")
		return
	end
	Script.Storage.lists[target] = nil
	if Script.SaveStorage() and not Script.Storage.config.SuppressStatusMessages then
		Game.PrintMessage(string.format("Deleted list [%s]", target))
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
	if not target then
		Game.PrintError("No list name specified")
		return
	end
	local list = Script.Storage.lists[target]
	if type(list) ~= "table" then
		Game.PrintError(string.format("No such list [%s]", target))
		return
	end
	if #list == 0 then
		Game.PrintError(string.format("No entries in list [%s]", target))
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
	if not target then
		Game.PrintError("No list name specified")
		return
	end
	local list = Script.Storage.lists[target]
	if type(list) ~= "table" then
		Game.PrintError(string.format("No such list [%s]", target))
		return
	end
	if #list == 0 then
		Game.PrintError(string.format("No entries in list [%s]", target))
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
	if not target then
		Game.PrintError("No list name specified")
		return
	end
	local list = Script.Storage.lists[target]
	if type(list) ~= "table" then
		Game.PrintError(string.format("No such list [%s]", target))
		return
	end
	if #list == 0 then
		Game.PrintError(string.format("No entries in list [%s]", target))
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
	if not target then
		Game.PrintError("No configuration setting specified")
		return
	end
	local cfg = Script.Storage.config
	local typ = type(cfg[target])
	if typ == "boolean" then
		if contains(valueTrue, value) then
			cfg[target] = true
		elseif contains(valueFalse, value) then
			cfg[target] = false
		elseif contains(valueToggle, value) then
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

local function core(textline)
	local action, args = shiftWord(textline, string.lower)
	if contains(cmdHelp, action) then
		Help()
	elseif contains(cmdList, action) then
		if #args > 0 then -- displaying the contents of a named list (with indexes)
			DisplayContents(args)
		else -- displaying all known list names (with the number of entries)
			ListNames()
		end
	elseif contains(cmdAdd, action) then
		AddItem(args)
	elseif contains(cmdRemove, action) then
		RemoveItem(args)
	elseif contains(cmdClear, action) then
		ClearList(args)
	elseif contains(cmdDelete, action) then
		DeleteList(args)
	elseif contains(cmdRename, action) then
		RenameList(args)
	elseif contains(cmdPick, action) then
		EchoItem(args)
	elseif contains(cmdExecute, action) then
		ExecuteItem(args)
	elseif contains(cmdEvaluate, action) then
		EvaluateItem(args)
	elseif contains(cmdConfig, action) then
		Configure(args)
	else
		Game.PrintMessage(string.format("Unknown command [%s]", action))
		Game.PrintMessage(string.format("Use [%s %s %s] for command help", Script.PluginCommand, Script.Name, cmdHelp[1]))
	end
end

Script(core)

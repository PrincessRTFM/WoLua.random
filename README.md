# Requires WoLua
This is a [WoLua] command script for FFXIV. You will need to install the WoLua plugin via Dalamud (instructions at link) in order to use it.

![GitHub last commit (branch)](https://img.shields.io/github/last-commit/PrincessRTFM/WoLua.random/master?label=updated)
[![GitHub issues](https://img.shields.io/github/issues-raw/PrincessRTFM/WoLua.random?label=known%20issues)](https://github.com/PrincessRTFM/WoLua.random/issues?q=is%3Aissue+is%3Aopen+sort%3Aupdated-desc)

## Usage
For all script commands, remember that they must be passed to `/wolua call <script> <command>`. If you have installed this script as `random` within WoLua's script folder, you will need to run `/wolua call random <command>`. Other installation names will need to adjust accordingly. You can use any of the commands listed in the "aliases" under a given section.

### Help
- _Aliases: `help`, `?`, empty string_
- _Arguments: none_
- _Example: `/wolua call random`_

This script includes builtin albeit minimal help, to display all supported actions (using only the first name for each) with a brief description of what they do. It's context-aware and will reflect whatever you have actually named the script.

### List
- _Aliases: `list`, `show`, `ls`_
- _Arguments: list name (optional)_
- _Example: `/wolua call random list`, `/wolua call random list greetings`_

Used without arguments, this command will list all stored lists, with the number of entries they contain. Since that may be a lot, they are listed on one line, to avoid overly cluttering your chatlog.

Used with the name of an existing list, this command will display all entries that list contains. This display will necessarily be one item per line, and each item will be prefixed with its "index" in the list, for use with the item deletion command.

Used with the name of a _non_-existent list, this command will return an error, telling you that no such list could be found.

### Add item
- _Aliases: `add`, `new`_
- _Arguments: list name, item contents_
- _Example: `/wolua call random add greetings /laliho`_

This command adds an item - which may be empty - to the end of the given list. Spaces _are_ stripped fully (see `shiftWord.lua` for the function used) before the item is appended.

If the named list doesn't exist, it will be created and the given item will be appended to it, leaving it with only that item.

### Remove item
- _Aliases: `del`, `delete`, `remove`, `rm`_
- _Arguments: list name, item index (optional)_
- _Example: `/wolua call random del greetings`, `/wolua call random del greetings 3`_

This command removes an item from the given list by index, which can be found via the [display list] command. If no index is provided, the last item on the list will be removed. If the item removed isn't at the end of the list, all subsequent item indexes are adjusted to close the gap.

If the given index is invalid (less than one or greater than the number of items in the list) then an error is displayed and nothing happens.

### Clear list
- _Aliases: `clear`, `empty`_
- _Arguments: list name_
- _Example: `/wolua call random clear greetings`_

This command removes ALL items from the given list, entirely clearing it without deleting it. It will still show up in the [show lists] command's output, but will do nothing with the [echo], [execute], or [evaluate] commands.

If the named list doesn't exist, it _will be created_, leaving it empty.

### Delete list
- _Aliases: `delete-list`, `deletelist`_
- _Arguments: list name_
- _Example: `/wolua call random delete-list greetings`_

This command will **entirely delete** a list from storage. The list will no longer exist at all afterward, meaning it will no longer show up in the [show lists] command's output, and attempting to use it with the [display list], [remove item], [rename list] (as source list), [echo], [execute], or [evaluate] commands will fail.

If the named list doesn't exist, nothing will technically happen, but the status message will still reflect success.

### Copy list
- _Aliases: `copy`, `clone`, `cp`_
- _Arguments: current list name, new list name_
- _Example: `/wolua call random copy hello greetings`_

This command allows you to easily copy a list from one name to another, without having to manually copy items or edit the storage file on disk. Please note that the "source" list _must_ exist (or you will get an error), and the "destination" name must _not_ be an existing list (or you will also get an error), so as to avoid accidentally clobbering something. If you wish to replace an existing list with another, you will need to [delete the target list][delete list] first.

### Rename list
- _Aliases: `move`, `rename`, `mv`_
- _Arguments: current list name, new list name_
- _Example: `/wolua call random move hello greetings`_

This command is very similar to the [copy list] command, with exactly one difference: **the "source" list will be deleted** afterward. All the same caveats from copying still apply though.

Please note that while this command is _functionally_ identical to copying a list and then [deleting the original][delete list], the internal implementation is faster since copying a list requires that each individual item be copied one-by-one, while moving a list does not. The technical reasons for this are beyond the scope of this document.

### Echo item
- _Aliases: `echo`, `pick`, `get`_
- _Arguments: list name_
- _Example: `/wolua call random echo greetings`_

This command will select a random item from the named list, and echo it to your local chatlog. Nobody else will be able to see it. This may be useful when doing treasure dungeons, for example, to echo a clear "left door" or "right door" choice. It's also invaluable for debugging lists that _are_ intended to send to the server with the [execute] and [evaluate] commands, for safety.

### Execute item
- _Aliases: `execute`, `exec`, `call`, `run`, `do`_
- _Arguments: list name_
- _Example: `/wolua call random execute greetings`_

This command will select a random item from the named list, and then send it to the game as chat input. **This is dangerous** for obvious reasons, so it is strongly advised to heavily debug your list contents with the [echo] command first.

Please note that it _is_ possible to use "raw text" input without a leading `/`, in which case the **text will be sent as a message on your current chat channel**. However, for safety's sake, this requires that you enable the [`AllowRawChatInput`][raw chat input] script [configuration setting][configuration] first.

For instance, in the example given for this command, if the `greetings` list contained `/wave`, `/laliho`, and `/welcome`, you would use one of those three emotes at random.

### Evaluate item
- _Aliases: `evaluate`, `eval`_
- _Arguments: list name, base chat input line_
- _Example: `/wolua call random evaluate mounts /mount "$$$"`_

This command is similar to the [execute] command, but allows more control. After the list name, you must provide an input line containing _at least one_ instance of three dollar signs (`$$$`) somewhere in it. When an item is selected, _all_ instances of this token in the provided input line are replaced with the selected item. The result is then checked for two things:

First, it must differ from the raw input line you provided. If this is not the case, the command will abort to ensure that you didn't make a mistake and accidentally provide an input line that doesn't have a replacement token, which would defeat the entire purpose of this command.

Second, if you _haven't_ enabled [raw chat input], the result _must_ begin with a `/` character, to form a chat command rather than a text message. This is to ensure that you don't accidentally send a visible message if something is malformed, since that might be suspicious to other players, especially if you're using plugin commands.

If these two checks both pass, the resulting text line is sent to the game. For instance, in the example given for this command, if the `mounts` list returned `Regalia Type-G`, the executed command would be `/mount "Regalia Type-G"`, which would result in using the Regalia mount (or an error if you don't have it unlocked).

This makes an easy way to create a game macro that selects a random mount or minion from a particular list for use, which would allow you to effectively whitelist more than can be favourited in the game, or to have separate lists for different situations, without needing to make every item in the list the full command as the [execute] action would.

### Export list
- _Aliases: `export`_
- _Arguments: list name_
- _Example: `/wolua call random export greetings`_

This command allows you to export a list as a JSON string for sharing with others using this script. The resulting JSON will automatically be copied to your system clipboard, and a status message will be printed to your chatlog (unless [suppressed][status messages]) with the number of items and the list name. You can then send this to someone else for use with the [import list] command.

### Import list
- _Aliases: `import`_
- _Arguments: target list name_
- _Example: `/wolua call random import greetings`_

This command is the counterpart to the [export list] command, and is the functional inverse. Your system clipboard will be read and parsed as JSON, and if it contains a valid list (ie, an array, not an object) then the result will be imported as a new list with the given name. The named list must _not_ exist, to prevent accidentally clobbering something. If you want to replace a list, first use the [delete list] command on it. On success, a status message will be printed to your chatlog (unless [suppressed][status messages]) with the number of items imported and the name of the new list.

Please note that you _can_ import an empty list, provided your clipboard contents are in fact an empty JSON array (`[]`) _or_ object (`{}`). Technically speaking, an object whose keys _imitate_ an array (all sequential positive integers) is also accepted and will be imported succesfully.

### Configuration
- _Aliases: `config`, `configure`, `setting`_
- _Arguments: setting name, new value (may be optional)_
- _Example: `/wolua call random config SilentExecution toggle`_

This script has several configuration options that can adjust output, detailed below. All options are persisted via WoLua's persistent script storage mechanism, so you only need to set them once. At present, there are only boolean (toggle) settings, but more may be added in the future.

All setting names are CASE-SENSITIVE.

#### Booleans

To change the value of a boolean, you can provide `true`, `on`, `yes`, `enable`, or `enabled` as the new value to turn it on; `false`, `off`, `no`, `disable`, or `disabled` to turn it off; or `toggle`, `flip`, `invert`, or an empty string to toggle it. For example, `/wolua call random config SilentExecution on` will enable the `SilentExecution` setting, regardless of whether it was previously on or off.

## Script settings

### `SuppressWarnings`
- _Type: boolean_
- _Default: `false`

If enabled, the following warnings will not be printed:

- Trying to use the [echo], [execute], and [evaluate] commands with an empty list. Non-existent lists will always print an error, as they may indicate a typo.
- [Displaying all list names][show lists] when there are no lists.

### `SuppressStatusMessages`
- _Type: boolean_
- _Default: `false`

If enabled, the following status output messages will not be printed:

- An item has been [added to a list][add item].
- An item was successfully [removed from a list][remove item]. Failures will print warnings instead, as they may indicate a mistake.
- A list was [cleared of all items][clear list].
- A list was [deleted entirely][delete list].
- A list was [copied to a new name][copy list].
- A list was [moved to a new name][rename list].

### `VerboseSelection`
- _Type: boolean_
- _Default: `false`

This controls the format of the [echo] command's output. If enabled, the list name and item index will be printed with a message, followed by the item itself on a separate line. If disabled, the item index and content will be printed on a single line, separated by a colon.

### `SilentExecution`
- _Type: boolean_
- _Default: `false`

If enabled, the [execute] and [evaluate] commands will print the resulting (constructed, in the case of evaluation) chat input to be executed before executing it. This will still be printed even if nothing is executed (because the result doesn't have a leading `/` and [raw chat input] is disabled) and is inteded for debugging and safety purposes.

### `AllowRawChatInput`
- _Type: boolean_
- _Default: `false`

:warning: **It is strongly recommended to keep this disabled.**

The [execute] and [evaluate] commands send chat input to the game, similar to it being typed into your chatlog input manually. If that chat input does _not_ begin with a leading slash character, **it is treated as a plain message** rather than a chat command, meaning it will be sent on your current chat channel. This setting exists to provide some measure of safety against accidentally saying something when you wanted to run a chat command instead.

For example, if you had a list of `/tp` commands for use with the Teleporter plugin to go to a random map zone for FATE grinding or something similar, and one of the items in the list was entered with a typo where the leading slash was missing, drawing that item with the [execute] command would _say_ `tp Wherever` in your active chat channel, which would be suspicious to other players. However, if this settings is disabled, nothing would happen and you would instead be presenting with an error so you can fix it.



[WoLua]: <https://github.com/PrincessRTFM/WoLua>
[show lists]: <#list>
[display list]: <#list>
[add item]: <#add-item>
[remove item]: <#remove-item>
[clear list]: <#clear-list>
[delete list]: <#delete-list>
[copy list]: <#copy-list>
[rename list]: <#rename-list>
[echo]: <#echo-item>
[execute]: <#execute-item>
[evaluate]: <#evaluate-item>
[export list]: <#export-list>
[import list]: <#import-list>
[configuration]: <#configuration>
[warnings]: <#suppresswarnings>
[status messages]: <#suppressstatusmessages>
[verbose selection]: <#verboseselection>
[silent execution]: <#silentexecution>
[raw chat input]: <#allowrawchatinput>

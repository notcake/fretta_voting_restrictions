-- Previously played gamemodes are stored in two places:
--  1. [FILE] data/fretta_last_gamemodes.txt
--		Contains a list of previously played gamemodes, including the currently running one
--  2. [LUA]  lastGamemodes
--      Contains a list of previously played gamemodes, excluding the currently running one

local lastGamemodeLimit = 1	-- number of previously played gamemodes to disable
local lastGamemodes = {}	-- list of previously played gamemodes

local ReadPreviousGamemodes
local TrimPreviousGamemodes
local WritePreviousGamemodes

local UpdateLastGamemode
local GetFrettaGamemodeCount
local IsFrettaRunning

local g_PlayableGamemodes = nil

-- Reads the list of previously played gamemodes from disk and appends the current gamemode
function ReadPreviousGamemodes ()
	local data = file.Read ("fretta_last_gamemodes.txt") or ""
	local lines = string.Explode ("\n", data)
	
	for _, v in ipairs (lines) do
		v = v:Trim ()
		if v ~= "" then
			lastGamemodes [#lastGamemodes + 1] = v:Trim ()
		end
	end
	lastGamemodes [#lastGamemodes + 1] = GAMEMODE.FolderName
	
	TrimPreviousGamemodes (lastGamemodeLimit)
end

-- Cuts down list of previously played gamemodes to the right size
function TrimPreviousGamemodes (n)
	while #lastGamemodes > n do
		table.remove (lastGamemodes, 1)
	end
end

-- Writes the list of previously played gamemodes to disk
function WritePreviousGamemodes ()
	local data = ""
	for _, v in ipairs (lastGamemodes) do
		data = data .. v .. "\n"
	end
	
	file.Write ("fretta_last_gamemodes.txt", data)
end

-- Adds the current gamemode to the 
function UpdateLastGamemode ()
	ReadPreviousGamemodes ()
	WritePreviousGamemodes ()
	TrimPreviousGamemodes (GetFrettaGamemodeCount () - 1)
end

function GetFrettaGamemodeCount ()
	local count = 0
	for _, _ in pairs (g_PlayableGamemodes) do
		count = count + 1
	end
	return count
end

function IsFrettaRunning ()
	return GetRandomGamemodeName and true or false
end

hook.Add ("Initialize", "Fretta Voting Control", function ()
	if not IsFrettaRunning () then return end
	
	-- link g_PlayableGamemodes
	local i = 1
	local upvalueName = nil
	local upvalue = nil
	while true do
		upvalueName, upvalue = debug.getupvalue (GetRandomGamemodeName, i)
		if not upvalueName then break end
		if upvalueName == "g_PlayableGamemodes" then
			g_PlayableGamemodes = upvalue
			break
		end
	end
	
	UpdateLastGamemode ()
	
	if not g_PlayableGamemodes then
		error ("Fretta Voting Restrictions: Failed to acquire g_PlayableGamemodes")
		return
	end
	
	-- Remove previously played gamemodes from the list of available gamemodes
	for _, v in ipairs (lastGamemodes) do
		g_PlayableGamemodes [v] = nil
	end
end)
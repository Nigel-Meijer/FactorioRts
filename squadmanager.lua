--[[============================================================================= 
#  Author:          Snoetje & exabyte
#  FileName:        squadmanager.lua
#  Description:     Rts Soft mod
#  Version:         1.1
#  LastChange:      2018-12-19
#  History:         
=============================================================================--]]

local event = require 'utils.event'
local SquadManager = {}


local function OnPlayerCreated(event)
    -- init squad manager vars.
    global.squadManager = global.squadManager or {}
	global.squadManager.nextUniqueSquadID = global.squadManager.nextUniqueSquadID or 1
    global.squadManager.squads = global.squadManager.squads or {}
end

-- Adds a unitgroup to the SquadManager and returns that id.
function SquadManager.Add(unitGroup)
    local usedSquadID = global.squadManager.nextUniqueSquadID
    
    -- increment the unique ID
    global.squadManager.nextUniqueSquadID = global.squadManager.nextUniqueSquadID + 1

    -- add the group to the table
    global.squadManager.squads[usedSquadID] = unitGroup
	return usedSquadID
end

function SquadManager.Delete(squadID)
    -- Make sure the group is still there.
    if global.squadManager.squads[squadID] ~= nil then

        -- Destroy the group if there is any.
        if global.squadManager.squads[squadID].valid then
            SquadManager.GetSquad(squadID).destroy()
        end

        --TODO Remove from players squad list. ?

        -- Delete the group from the table.
        global.squadManager.squads[squadID] = nil
	end
end

-- used to garbage collect the killed squads.
function SquadManager.GarbageCollect()
    for squadID, squad in pairs(global.squadManager.squads) do 
        if squad.valid == false then
            game.print("Squad: " .. squadID .. " was killed in action.")
            -- NOTE: Could create a custom event to notice player that squad died.
            SquadManager.Delete(squadID)
        end
    end
end

-- Searches for the group index in the table.
function SquadManager.FindSquadID(unitGroup)
    for squadID, squad in pairs(global.squadManager.squads) do 
        if squad == unitGroup then
            return squadID
        end
    end

    -- if no squad found return 0
    return 0
end

function SquadManager.GetSquad(squadID)
    if global.squadManager.squads[squadID] ~= nil then
        if global.squadManager.squads[squadID].valid then
            return global.squadManager.squads[squadID]
        end
    end

    return nil
end

function SquadManager.ResetSquads()
	-- Empty the squad lists
end

function SquadManager.CountSquads()
    local count = 0
    for _, _ in pairs(global.squadManager.squads) do 
        count = count + 1
    end

    return count
	-- Empty the squad lists
end


--[[
    	local start = global.squadManager.nextUniqueSquadID
	for i = 1, 100000, 1 do
		global.squadManager.squads[global.squadManager.nextUniqueSquadID] = global.squadManager.nextUniqueSquadID
		global.squadManager.nextUniqueSquadID = global.squadManager.nextUniqueSquadID + 1
	end

	for i = 1, 100000, 1 do
		global.squadManager.squads[start] = nil
		start = start + 1
	end

	
	game.print(global.squadManager.nextUniqueSquadID)
--]]

event.add(defines.events.on_player_created, OnPlayerCreated)


return SquadManager
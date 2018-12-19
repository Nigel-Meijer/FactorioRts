--[[============================================================================= 
#  Author:          Snoetje & exabyte
#  FileName:        interface.lua
#  Description:     Rts Soft mod
#  Version:         1.1
#  LastChange:      2018-12-19
#  History:         
=============================================================================--]]
local event = require 'utils.event'
local squad = require 'squads'

local function OnPlayerCreated(event)
	-- init interface
	global.players[event.player_index].interface = {}
	global.players[event.player_index].interface.lastLeftClickOnTick = 0	-- Used for registering double clicks
	global.players[event.player_index].interface.lastLeftClickArea = {}		-- Backup of the area that was last selected.
end

-- Function to handle single click input.

local function LeftClickSingleWithShift(player_index,area)
    squad.SelectNearest(player_index, area)
    if DEBUG_INTERFACE_COMMANDS then game.players[player_index].print("Select Nearest") end
end

local function LeftClickSingle(player_index)
    local area = global.players[player_index].interface.lastLeftClickArea
    local areasize = (area.left_top.x - area.right_bottom.x) * (area.left_top.y - area.right_bottom.y)

    if(areasize < AREASIZE_FOR_MOVE) then
        if squad.IsSquadSelected(player_index) then
            squad.Move(player_index, area)
            if DEBUG_INTERFACE_COMMANDS then game.players[player_index].print("Move") end
        end


    else
        squad.SelectInArea(player_index, area)
        if DEBUG_INTERFACE_COMMANDS then game.players[player_index].print("Select in Area") end
    end
end

--Function to handle double click input
local function LeftClickDouble(player_index,area)
    if squad.IsSquadSelected(player_index) then
        squad.Attack(player_index, area)
        if DEBUG_INTERFACE_COMMANDS then game.players[player_index].print("Attack") end
    end
end


--Handler for handling a single click
local function SingleClickHandler(player_index)
    -- if lastLeftClickOnTick == 0 means there is no click to handle.
	if global.players[player_index].interface.lastLeftClickOnTick ~= 0 then
        local timeSinceLastClick = game.tick - global.players[player_index].interface.lastLeftClickOnTick

        -- If last click > max double click time.
        if timeSinceLastClick > DOUBLE_CLICK_TIME_IN_TICKS_MAX then
            --execute single click
			LeftClickSingle(player_index)

            -- Reset the last leftclick.
			global.players[player_index].interface.lastLeftClickOnTick = 0
		end
	end
end

-- Handler for handling the single clicks for connected players in RTSMode.
local function OnTickInterfaceHandler(event)
    -- Loop over all connected players which have rtsmode enabled.
	for _, player in pairs(game.connected_players) do
        if global.players[player.index].isRtsMode then

            -- Run the single click handler.
			SingleClickHandler(player.index)
		end
	end
end

local function on_player_deconstructed_area(event)
    if not global.players[event.player_index].isRtsMode then return end
    
    if event.alt then
        LeftClickSingleWithShift(event.player_index, event.area)

        -- make sure this is reset incase of -> left click, left click shift.
        global.players[event.player_index].interface.lastLeftClickOnTick = 0
        return
    end

    local timeSinceLastClick = game.tick - global.players[event.player_index].interface.lastLeftClickOnTick
    
    -- if last click between min/max to register a doubleclick
    if timeSinceLastClick > DOUBLE_CLICK_TIME_IN_TICKS_MIN and timeSinceLastClick < DOUBLE_CLICK_TIME_IN_TICKS_MAX then
        -- Execute double click.
        LeftClickDouble(event.player_index, event.area)
        
        -- Reset the last leftclick.
		global.players[event.player_index].interface.lastLeftClickOnTick = 0
    else
        -- if there is no double click register the tick and event.area. Which will be handled in 
        -- OnTickInterfaceHandler when no double click is registered
        global.players[event.player_index].interface.lastLeftClickOnTick = game.tick
        global.players[event.player_index].interface.lastLeftClickArea = event.area
	end
end

local function on_player_cursor_stack_changed(event) 
    local player = game.players[event.player_index]
    
	if IsRtsModeEnabled(event.player_index) then
		local cursorStack = player.cursor_stack
		if cursorStack and cursorStack.is_deconstruction_item then
			local filters = cursorStack.entity_filters
			for i = 1, #filters do
				if filters[i] ~= "fish" then return end
			end

			-- its a valid squad planner
			squad.SelectSquadNumber(player, #filters)
		end
	end
end

local function on_marked_for_deconstruction(event)
    if not IsRtsModeEnabled(event.player_index) then return end
	
	-- We are only doing this for the area selection so cancel the deconstruction.
	event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
end

event.add(defines.events.on_player_created, OnPlayerCreated)
event.add(defines.events.on_player_deconstructed_area, on_player_deconstructed_area)
event.add(defines.events.on_tick, OnTickInterfaceHandler)
event.add(defines.events.on_player_cursor_stack_changed, on_player_cursor_stack_changed)
event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
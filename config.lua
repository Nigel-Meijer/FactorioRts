--[[============================================================================= 
#  Author:          Snoetje & exabyte
#  FileName:        config.lua
#  Description:     Rts Soft mod
#  Version:         1.1
#  LastChange:      2018-11-30
#  History:         
=============================================================================--]]

local event = require 'utils.event'



-- Interface settings
DOUBLE_CLICK_TIME_IN_TICKS_MIN = 1    -- Minimum time that is needed to register a double click.
DOUBLE_CLICK_TIME_IN_TICKS_MAX = 15   -- Maximumm time that is needed to register a double click.

AREASIZE_FOR_MOVE = 1                 -- Size of area with planner used for -> move/attack in interface.lua.
AREASIZE_FOR_SELECT_MAX = 25000       -- Max areasize with planner for selecting biters in interface.lua.

-- Debug
DEBUG_INTERFACE_COMMANDS = true       -- Used to debug interface.lua single/double click


local function OnPlayerCreated(event)
    -- init global tables
    -- Created here so other luafiles can extend on the global.players table
	global.players = global.players or {}
	global.players[event.player_index] = global.players[event.player_index] or {}
end

event.add(defines.events.on_player_created, OnPlayerCreated)
--[[============================================================================= 
#  Author:          Snoetje & exabyte
#  FileName:        control.lua
#  Description:     Rts Soft mod
#  Version:         1.1
#  LastChange:      2018-12-19
#  History:         
=============================================================================--]]

require 'config' -- should always be the first require!
require 'rtsmode'
local event = require 'utils.event'
local gui = require 'gui'
local squadManager = require 'squadmanager'
require 'interface'

local function OnPlayerCreated(event)
	-- init tables
	global.players[event.player_index].selectedSquadID	= nil -- nil means nothing selected.
	global.players[event.player_index].nameBackup 		= ""
	global.players[event.player_index].colorBackup 		= nil
	global.players[event.player_index].isRtsMode 			= false
	global.players[event.player_index].squads				= {}
	
	-- init upgrades
	global.players[event.player_index].upgrades 			= {}
	global.players[event.player_index].upgrades.numOfSquads 	= { name = "Max number of squads", value = 1 }
	global.players[event.player_index].upgrades.squadSize 		= { name = "Maximum squad size", value = 10 }
	
	local player = game.players[event.player_index]	
	gui.Create_RtsButton(player)
	
	for name, recipe in pairs(player.force.recipes) do 
		recipe.enabled = true 
	end
end

local function on_gui_click(event)
	local player = game.players[event.player_index]

	local name = event.element.name
	
	if name == "RtsButton" then		
		if IsRtsModeEnabled(event.player_index) == false then
			SetRtsMode(event.player_index, true)
		elseif IsRtsModeEnabled(event.player_index) == true then
			SetRtsMode(event.player_index, false)
		end

	elseif name == "UpgradeMenuButton" then
		gui.Toggle_Gui(player, "upgradeGui")
		gui.Toggle_Gui(player, "squadGui")
	
	
	elseif string.find(name, "^squad_previewButton") then
		game.print("button clicked")
		local squadNum = tonumber(string.sub(name, -1))
		local foundSquad = nil
		local foundSquadID = nil
		local i = 0
		
		for _, squadID in pairs(global.players[player.index].squads) do
			local squad = squadManager.GetSquad(squadID)
			if squad ~= nil then
				if i == squadNum then 
					foundSquad = squad
					foundSquadID = squadID
					break
				end
				i = i + 1
			end
		end
		game.players[event.player_index].teleport(foundSquad.position)
		global.players[player.index].selectedSquadID = foundSquadID
	end
end

local function on_tick(event)
	if global.players[1].isRtsMode then
		if event.tick % 60 == 0 then
			gui.Update_Gui(game.players[1], "squadGui")
		end
		if event.tick % 5 == 0 then
			for _, player in pairs(game.players) do
				if global.players[player.index].isRtsMode then
					gui.Update_SquadGui_Tick(player)
				end
			end
		end
	end
end

event.add(defines.events.on_player_created, OnPlayerCreated)
event.add(defines.events.on_gui_click, on_gui_click)

event.add(defines.events.on_tick, on_tick)
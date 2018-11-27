--[[============================================================================= 
#  Author:          Snoetje
#  FileName:        rtsmode.lua
#  Description:     Rts Soft mod
#  Version:         1.0
#  LastChange:      2018-11-22
#  History:         
=============================================================================--]]

local event = require 'utils.event'


local function RtsModeEnable(player)
	global.players[player.index].isRtsMode = true
end

local function RtsModeDisable(player)
	global.players[player.index].isRtsMode = false
end

local function IsRtsModeEnabled(player)
	return global.players[player.index].isRtsMode
end


local function BackupPlayer(player)
	-- Make a backup
	global.players[player.index].nameBackup = player.name
	global.players[player.index].colorBackup = player.color
	
	--Remove name and make player dot opaque
	player.name = " "
	player.color = {r=0.0, g=0.0, b=0.0, a=0.0}
end

local function RestorePlayer(player)
	player.name = global.players[player.index].nameBackup
	player.color = global.players[player.index].nameBackup
end

local function on_player_deconstructed_area(event)
	if not global.players[event.player_index].isRtsMode then return end
	
	if event.alt then
		if global.players[event.player_index].selectedGroup ~= nil and #global.players[event.player_index].selectedGroup.members > 0 then
			-- b_command = defines.command.attack_area
			-- b_distraction = defines.distraction.by_damage
		
			-- global.selectedGroup[event.player_index].set_command({type=b_command, destination=event.area.left_top, distraction=b_distraction, radius=1})
			
			-- cache all members of old group
			local members = global.players[event.player_index].selectedGroup.members
			
			-- remove old group and create a new one at target position
			global.players[event.player_index].selectedGroup.destroy()
			global.players[event.player_index].selectedGroup = game.surfaces[1].create_unit_group({position=event.area.left_top})
			for _, biter in pairs(members) do
				global.players[event.player_index].selectedGroup.add_member(biter)
			end
		end
	else
		--local init_pos = {x=(event.area.left_top.x + event.area.right_bottom.x) / 2, y=(event.area.left_top.y + event.area.right_bottom.y) / 2}
		-- dont find entities filtered if area is 0 (not allowed)
		local biters = {}
		if not (event.area.left_top.x == event.area.right_bottom.x and event.area.left_top.y == event.area.right_bottom.y) then 
			biters = game.surfaces[1].find_entities_filtered{area = event.area, type= "unit"}
		end
		
		if #biters == 0 then return end
		global.players[event.player_index].selectedGroup = game.surfaces[1].create_unit_group({position=event.area.left_top})
		
		-- cache all groups selected biters were part of
		local otherGroups = {}
		for _, biter in pairs(biters) do
			if biter.unit_group then otherGroups[biter.unit_group] = true end
			global.players[event.player_index].selectedGroup.add_member(biter)
		end
		
		-- remove empty groups created by merging
		for group, _ in pairs(otherGroups) do
			if not (group == global.players[event.player_index].selectedGroup) then
				game.print("group with " .. #group.members .. " members")
				if #group.members == 0 then group.destroy() end
			end
		end
		
		game.print("Selected: " .. #global.players[event.player_index].selectedGroup.members)
	end
end

local function Create_RtsButton(player)
	if player.gui.top.RtsButton == nil then
		local button = player.gui.top.add { name = "RtsButton", type = "sprite-button", sprite = "entity/small-biter" }
		button.style.font = "default-bold"
		button.style.minimal_height = 38
		button.style.minimal_width = 38
		button.style.top_padding = 2
		button.style.left_padding = 4
		button.style.right_padding = 4
		button.style.bottom_padding = 2
	end
end

local function OnPlayerCreated(event)
	
	-- init tables
	global.players = global.players or {}
	
	global.players[event.player_index] = {}

	global.players[event.player_index].selectedGroup	= nil
	global.players[event.player_index].nameBackup 		= ""
	global.players[event.player_index].colorBackup 		= nil
	global.players[event.player_index].isRtsMode 			= false
	
	local player = game.players[event.player_index]	
	Create_RtsButton(player)
	
	for name, recipe in pairs(player.force.recipes) do 
		recipe.enabled = true 
	end
end

local function on_marked_for_deconstruction(event)
	if not global.players[event.player_index].isRtsMode then return end
	
	-- We are only doing this for the area selection so cancel the deconstruction.
	event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
end

local function on_gui_click(event)
	local player = game.players[event.player_index]
	
	local name = event.element.name
	if name == "RtsButton" then		
		if IsRtsModeEnabled(player) == false then
			RtsModeEnable(player)

			-- Destroy the players character and give him a rts tool
			player.character.destroy()
			player.insert{name="deconstruction-planner", count = 1}
			
			-- Backup username and color and make name blank
			BackupPlayer(player)
			
		elseif IsRtsModeEnabled(player) == true then
			RtsModeDisable(player)
			
			-- Create a character and restore name / color
			player.create_character()
			RestorePlayer(player)
			
		end
	end
end

event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
event.add(defines.events.on_player_deconstructed_area, on_player_deconstructed_area)
event.add(defines.events.on_player_created, OnPlayerCreated)
event.add(defines.events.on_gui_click, on_gui_click)
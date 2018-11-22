--[[============================================================================= 
#  Author:          Snoetje
#  FileName:        rtsmode.lua
#  Description:     Rts Soft mod
#  Version:         1.0
#  LastChange:      2018-11-22
#  History:         
=============================================================================--]]


local event = require 'utils.event'
global.selectedEntities = global.selectedEntities or {}
global.playerNameBackup = global.playerNameBackup or {}
global.playerColorBackup = global.playerColorBackup or {}
global.playerRtsMode = global.playerRtsMode or {}


local function RtsModeEnable(player)
	global.playerRtsMode[player.index] = true
end

local function RtsModeDisable(player)
	global.playerRtsMode[player.index] = false
end

local function IsRtsModeEnabled(player)
	if global.playerRtsMode[player.index] then
		return true
	else
		return false
	end
end


local function BackupPlayer(player)
	-- Make a backup
	global.playerNameBackup[player.index] = player.name
	global.playerColorBackup[player.index] = player.color
	
	--Remove name and make player dot opaque
	player.name = " "
	player.color = {r=0.0, g=0.0, b=0.0, a=0.0}
end

local function RestorePlayer(player)
	player.name = global.playerNameBackup[player.index]
	player.color = global.playerColorBackup[player.index]
end

local function on_player_deconstructed_area(event)
	if not IsRtsModeEnabled(game.players[event.player_index]) then return end
	
	if event.alt then
		if global.selectedEntities[event.player_index] ~= nil and #global.selectedEntities[event.player_index].members > 0 then
			-- b_command = defines.command.attack_area
			-- b_distraction = defines.distraction.by_damage
		
			-- global.selectedEntities[event.player_index].set_command({type=b_command, destination=event.area.left_top, distraction=b_distraction, radius=1})
			local members = global.selectedEntities[event.player_index].members
			global.selectedEntities[event.player_index].destroy()
			global.selectedEntities[event.player_index] = game.surfaces[1].create_unit_group({position=event.area.left_top})
			for _, biter in pairs(members) do
				global.selectedEntities[event.player_index].add_member(biter)
			end
		end
	else
		--local init_pos = {x=(event.area.left_top.x + event.area.right_bottom.x) / 2, y=(event.area.left_top.y + event.area.right_bottom.y) / 2}
		local biters = game.surfaces[1].find_entities_filtered{area = event.area, type= "unit"}
		if #biters == 0 then return end
		global.selectedEntities[event.player_index] = game.surfaces[1].create_unit_group({position=event.area.left_top})
		
		local otherGroups = {}
		for _, biter in pairs(biters) do
			if biter.unit_group then otherGroups[biter.unit_group] = true end
			global.selectedEntities[event.player_index].add_member(biter)
		end
		
		-- remove empty groups created by merging
		for group, _ in pairs(otherGroups) do
			if not (group == global.selectedEntities[event.player_index]) then
				game.print("group with " .. #group.members .. " members")
				if #group.members == 0 then group.destroy() end
			end
		end
		
		game.print("Selected: " .. #global.selectedEntities[event.player_index].members)
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

	local player = game.players[event.player_index]	
	Create_RtsButton(player)
	
	for name, recipe in pairs(player.force.recipes) do 
		recipe.enabled = true 
	end
end

local function on_marked_for_deconstruction(event)
	if not IsRtsModeEnabled(game.players[event.player_index]) then return end
	
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
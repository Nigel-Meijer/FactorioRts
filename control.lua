--[[============================================================================= 
#  Author:          Snoetje & exabyte
#  FileName:        rtsmode.lua
#  Description:     Rts Soft mod
#  Version:         1.1
#  LastChange:      2018-11-30
#  History:         
=============================================================================--]]

local event = require 'utils.event'
local gui = require 'gui'


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
		if global.players[event.player_index].selectedSquad ~= nil and #global.players[event.player_index].selectedSquad.members > 0 then
			-- b_command = defines.command.attack_area
			-- b_distraction = defines.distraction.by_damage
			-- game.print(global.players[event.player_index].selectedSquad.state)
			-- global.players[event.player_index].selectedSquad.set_command(
			-- {type=defines.command.wander}
			-- -- {type=b_command, destination=event.area.left_top, distraction=b_distraction, radius=1}
			-- )
			-- game.print(global.players[event.player_index].selectedSquad.state)

			
			local command = {
				type = defines.command.compound,
				structure_type = defines.compound_command.return_last,
				commands = {
					{ type = defines.command.attack_area, destination = event.area.left_top, radius=4 },
					{ type = defines.command.wander, distraction = defines.distraction.none }
				}
			}
			global.players[event.player_index].selectedSquad.set_command(command)
			global.players[event.player_index].selectedSquad.start_moving()
			
			
			-- -- cache all members of old group
			-- local members = global.players[event.player_index].selectedSquad.members
			
			-- -- remove old group and create a new one at target position
			-- global.players[event.player_index].selectedSquad.destroy()
			-- global.players[event.player_index].selectedSquad = game.surfaces[1].create_unit_group({position=event.area.left_top})
			-- for _, biter in pairs(members) do
				-- global.players[event.player_index].selectedSquad.add_member(biter)
			-- end
		end
	else
		local init_pos = {x=(event.area.left_top.x + event.area.right_bottom.x) / 2, y=(event.area.left_top.y + event.area.right_bottom.y) / 2}
		
		-- dont find entities filtered if area is 0 (not allowed)
		local biters = {}
		
		if not (event.area.left_top.x == event.area.right_bottom.x and event.area.left_top.y == event.area.right_bottom.y) then 
			-- area select: form new group
			biters = game.surfaces[1].find_entities_filtered{area = event.area, type= "unit"}
		else
			-- click select: find nearest group in range
			local nearestGroup = nil
			local leastDist = 10 -- also used as max distance from click to unit group center
			for squad, isInSet in pairs(global.players[event.player_index].squads) do
				if not isInSet then goto continue end
				if (not squad.valid) or #squad.members == 0 then 
					global.players[event.player_index].squads[squad] = nil 
					goto continue 
				end
				
				local dist = math.sqrt((event.area.left_top.x - squad.position.x)^2 + (event.area.left_top.y - squad.position.y)^2)
				if dist < leastDist then nearestGroup = squad end
				::continue::
			end
			
			global.players[event.player_index].selectedSquad = nearestGroup
			return
		end
		
		if #biters == 0 then return end
		global.players[event.player_index].selectedSquad = game.surfaces[1].create_unit_group({ position=init_pos })
		-- add this squad to player's squads list
		global.players[event.player_index].squads[ global.players[event.player_index].selectedSquad ] = true
		gui.Update_Gui(game.players[ event.player_index ], "squadGui")
		
		
		-- cache all groups selected biters were part of
		local otherGroups = {}
		for _, biter in pairs(biters) do
			if biter.unit_group then otherGroups[biter.unit_group] = true end
			global.players[event.player_index].selectedSquad.add_member(biter)
		end
		
		-- remove empty groups created by merging
		for squad, _ in pairs(otherGroups) do
			if not (squad == global.players[event.player_index].selectedSquad) then
				-- game.players[event.player_index].print("squad with " .. #squad.members .. " members")
				if #squad.members == 0 then 
					global.players[event.player_index].squads[ squad ] = nil
					squad.destroy()
				end
			end
		end
		
		game.print("Selected: " .. #global.players[event.player_index].selectedSquad.members .. " biters")
	end
end

local function selectSquadNum(player, number)
	local i = 1
	for squad, isInSet in pairs(global.players[player.index].squads) do

		if not isInSet then goto continue end
		if (not squad.valid) then 
			global.players[player.index].squads[squad] = nil 
			goto continue
		end
		if #squad.members == 0 then goto continue end
		
		if i == number then
			global.players[player.index].selectedSquad = squad
			gui.Update_Gui(player, "squadGui")
			return
		end
		
		i = i + 1
		::continue::
	end
end

local function OnPlayerCreated(event)
	
	-- init tables
	global.players = global.players or {}
	
	global.players[event.player_index] = {}

	global.players[event.player_index].selectedSquad	= nil
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
				-- Fill inventory with Deconstruction planners
				local quickbar = player.get_quickbar()
				for i = 1,10,1 
				do 
					quickbar.set_filter(i,"deconstruction-planner")
					player.insert{name="deconstruction-planner", count = 1}
					for x = 1,i,1 
					do
						quickbar[i].set_entity_filter(x,"fish")
					end
				end
			
			-- Backup username and color and make name blank
			BackupPlayer(player)
			
		elseif IsRtsModeEnabled(player) == true then
			RtsModeDisable(player)
			
			-- Create a character and restore name / color
			player.create_character()
			RestorePlayer(player)
			
		end
	
	elseif name == "UpgradeMenuButton" then
		gui.Toggle_Gui(player, "upgradeGui")
		gui.Toggle_Gui(player, "squadGui")
	
	
	elseif string.find(name, "^squad_previewButton") then
		local squadNum = tonumber(string.sub(name, -1))
		local foundSquad = nil
		local i = 0
		
		for squad, isInSet in pairs(global.players[player.index].squads) do
			if not isInSet then goto continue end
			if (not squad.valid) --[[or #squad.members == 0]] then 
				global.players[player.index].squads[squad] = nil 
				goto continue
			end
			if i == squadNum then 
				foundSquad = squad
				break
			end
			i = i + 1
			::continue::
		end
		game.players[event.player_index].teleport(foundSquad.position)
		global.players[player.index].selectedSquad = foundSquad
	end
end

local function on_player_cursor_stack_changed(event) 
	game.print("event cursor stack changed fired")

	local player = game.players[event.player_index]
	if IsRtsModeEnabled(player) then
		local cursorStack = player.cursor_stack
		if cursorStack and cursorStack.is_deconstruction_item then
			game.print("item is decon item")
			local filters = cursorStack.entity_filters
			for i = 1, #filters do
				-- if not a valid squad planner, return
				game.print("filter[" .. i .. "] =  " .. filters[i])

				if filters[i] ~= "fish" then return end
			end
			game.print("found " .. #filters .. " fish")
			-- its a valid squad planner
			selectSquadNum(player, #filters)
		end
	end
end

local function on_tick(event)
	if global.players[1].isRtsMode then
		if event.tick % 60 == 0 then
			gui.Update_Gui(game.players[1], "squadGui")
		end
		if event.tick % 1 == 0 then
			for _, player in pairs(game.players) do
				if global.players[player.index].isRtsMode then
					gui.Update_SquadGui_Tick(player)
				end
			end
		end
	end
end

event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
event.add(defines.events.on_player_deconstructed_area, on_player_deconstructed_area)
event.add(defines.events.on_player_created, OnPlayerCreated)
event.add(defines.events.on_gui_click, on_gui_click)

event.add(defines.events.on_player_cursor_stack_changed, on_player_cursor_stack_changed)
event.add(defines.events.on_tick, on_tick)
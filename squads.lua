--[[============================================================================= 
#  Author:          Snoetje & exabyte
#  FileName:        squads.lua
#  Description:     Rts Soft mod
#  Version:         1.1
#  LastChange:      2018-12-19
#  History:         
=============================================================================--]]

local gui = require 'gui'
local squadManager = require 'squadmanager'
local Squad = {}

function Squad.Attack(player_index, area)
	-- if no squad selected.. exit
	if Squad.SquadSelected(player_index) == false then return end

	-- Get squad using the selectedSquadID.
	game.print("SelectedSquad = " .. global.players[player_index].selectedSquadID) 
	local squad = squadManager.GetSquad(global.players[player_index].selectedSquadID)

	-- if there is no squad using that id exit
	if squad == nil then
		-- clear selected squad
		global.players[player_index].selectedSquadID = nil
		 return 
	end

	if #squad.members > 0 then
		local command = {
			type = defines.command.compound,
			structure_type = defines.compound_command.return_last,
			commands = {
				{ type = defines.command.attack_area, destination = area.left_top, radius=4 },
				{ type = defines.command.wander, distraction = defines.distraction.none }
			}
		}
		squad.set_command(command)
		squad.start_moving()
	end
end

function Squad.Move(player_index, area)
	-- if no squad selected.. exit
	if Squad.SquadSelected(player_index) == false then return end

	-- Get squad using the selectedSquadID.
	--game.print("SelectedSquad = " .. global.players[player_index].selectedSquadID) 
	local squad = squadManager.GetSquad(global.players[player_index].selectedSquadID)

	-- if there is no squad using that id exit
	if squad == nil then
		-- clear selected squad
		global.players[player_index].selectedSquadID = nil
		 return 
	end

	if #squad.members > 0 then
		local command = {
			type = defines.command.compound,
			structure_type = defines.compound_command.return_last,
			commands = {
				{ type = defines.command.go_to_location, distraction = defines.distraction.none, destination = area.left_top,  radius=4 },
				{ type = defines.command.wander, 		 distraction = defines.distraction.none }
			}
		}
		squad.set_command(command)
		squad.start_moving()
	end
end

function Squad.SelectInArea(player_index, area)
	local init_pos = {x=(area.left_top.x + area.right_bottom.x) / 2, y=(area.left_top.y + area.right_bottom.y) / 2}
		
	-- dont find entities filtered if area is 0 (not allowed)
	local biters = {}
	
	if not (area.left_top.x == area.right_bottom.x and area.left_top.y == area.right_bottom.y) then 
		-- area select: form new group
		biters = game.surfaces[1].find_entities_filtered{area = area, type= "unit"}
	end
	
	if #biters == 0 then return end
	-- find a suitable non spawner-colliding position for the unit group to form
	local non_col_pos = game.surfaces[1].find_non_colliding_position("rocket-silo", init_pos, 0, 1)

	local newSquad = game.surfaces[1].create_unit_group({ position=non_col_pos })
	local squadID = squadManager.Add(newSquad)
	global.players[player_index].selectedSquadID = squadID

	-- add squadID to player's squads list
	table.insert(global.players[player_index].squads, squadID)

	gui.Update_Gui(game.players[player_index], "squadGui")
	
	-- cache all groups selected biters were part of
	local otherGroups = {}
	for _, biter in pairs(biters) do
		if biter.unit_group then otherGroups[biter.unit_group] = true end
		newSquad.add_member(biter)
	end
	
	-- remove empty groups created by merging
	for squad, _ in pairs(otherGroups) do
		-- game.players[event.player_index].print("squad with " .. #squad.members .. " members")
		if #squad.members == 0 then 
			local otherGroupID = squadManager.FindSquadID(squad)
			squadManager.Delete(otherGroupID)
		end
	end

	game.print("Selected: " .. #newSquad.members .. " biters ")
end

function Squad.SelectNearest(player_index, area)
	local nearestGroup = nil
	local leastDist = 10 -- also used as max distance from click to unit group center
	game.print(#global.players[player_index].squads)
	
	for _, squadID in pairs(global.players[player_index].squads) do

		local squad = squadManager.GetSquad(squadID)
		if not squadID then goto continue end
		if (not squad.valid) or #squad.members == 0 then 
			global.players[player_index].squads[squadID] = nil  -- TODO remove squad thingie is this nessecary, add to: SquadManager.Delete()?
			goto continue 
		end
		
		local dist = math.sqrt((area.left_top.x - squad.position.x)^2 + (area.left_top.y - squad.position.y)^2)
		if dist < leastDist then nearestGroup = squad end
		::continue::
	end
	
	global.players[player_index].selectedSquadID = squadManager.FindSquadID(nearestGroup)
	
end

function Squad.SelectSquadNumber(player, hotkey)
	local i = 1
	for _, squadID in pairs(global.players[player.index].squads) do
		local squad = squadManager.GetSquad(squadID)

		if not squadID then goto continue end
		if (not squad.valid) then 
			global.players[player.index].squads[squadID] = nil 
			goto continue
		end
		if #squad.members == 0 then goto continue end
		
		if i == hotkey then
			global.players[player.index].selectedSquadID = squadID
			gui.Update_Gui(player, "squadGui")
			return
		end
		
		i = i + 1
		::continue::
	end
end

function Squad.SquadSelected(player_index)
    if global.players[player_index].selectedSquadID ~= nil then
        return true
    end

    return false
end

return Squad
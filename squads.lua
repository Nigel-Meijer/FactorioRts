--[[============================================================================= 
#  Author:          Snoetje & exabyte
#  FileName:        squads.lua
#  Description:     Rts Soft mod
#  Version:         1.1
#  LastChange:      2018-12-19
#  History:         
=============================================================================--]]

local gui = require 'gui'
local Squad = {}

function Squad.Attack(player_index, area)
	if global.players[player_index].selectedSquad ~= nil and #global.players[player_index].selectedSquad.members > 0 then
		local command = {
			type = defines.command.compound,
			structure_type = defines.compound_command.return_last,
			commands = {
				{ type = defines.command.attack_area, destination = area.left_top, radius=4 },
				{ type = defines.command.wander, distraction = defines.distraction.none }
			}
		}
		global.players[player_index].selectedSquad.set_command(command)
		global.players[player_index].selectedSquad.start_moving()
	end
end

function Squad.Move(player_index, area)
	if global.players[player_index].selectedSquad ~= nil and #global.players[player_index].selectedSquad.members > 0 then
		local command = {
			type = defines.command.compound,
			structure_type = defines.compound_command.return_last,
			commands = {
				{ type = defines.command.go_to_location, distraction = defines.distraction.none, destination = area.left_top,  radius=4 },
				{ type = defines.command.wander, 		 distraction = defines.distraction.none }
			}
		}
		global.players[player_index].selectedSquad.set_command(command)
		global.players[player_index].selectedSquad.start_moving()
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
	global.players[player_index].selectedSquad = game.surfaces[1].create_unit_group({ position=non_col_pos })
	-- add this squad to player's squads list
	global.players[player_index].squads[global.players[player_index].selectedSquad] = true
	gui.Update_Gui(game.players[player_index], "squadGui")
	
	-- cache all groups selected biters were part of
	local otherGroups = {}
	for _, biter in pairs(biters) do
		if biter.unit_group then otherGroups[biter.unit_group] = true end
		global.players[player_index].selectedSquad.add_member(biter)
	end
	
	-- remove empty groups created by merging
	for squad, _ in pairs(otherGroups) do
		if not (squad == global.players[player_index].selectedSquad) then
			-- game.players[event.player_index].print("squad with " .. #squad.members .. " members")
			if #squad.members == 0 then 
				global.players[player_index].squads[ squad ] = nil
				squad.destroy()
			end
		end
	end
	
	game.print("Selected: " .. #global.players[player_index].selectedSquad.members .. " biters")

end

function Squad.SelectNearest(player_index, area)
	local nearestGroup = nil
	local leastDist = 10 -- also used as max distance from click to unit group center
	game.print(#global.players[player_index].squads)
	for squad, isInSet in pairs(global.players[player_index].squads) do
		if not isInSet then goto continue end
		if (not squad.valid) or #squad.members == 0 then 
			global.players[player_index].squads[squad] = nil 
			goto continue 
		end
		
		local dist = math.sqrt((area.left_top.x - squad.position.x)^2 + (area.left_top.y - squad.position.y)^2)
		if dist < leastDist then nearestGroup = squad end
		::continue::
	end
	
	global.players[player_index].selectedSquad = nearestGroup
end

function Squad.SelectSquadNumber(player, number)
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

function Squad.IsSquadSelected(player_index)
    if global.players[player_index].selectedSquad ~= nil then
        return true
    end

    return false
end

return Squad
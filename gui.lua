local Gui = {}

function Gui.Create_Gui(player, guiName)
	--[[
	if guiName == "upgradeGui" then
		local upgradeGui = player.gui.top.rtsGui.add{ name = "upgradeGui", type = "frame", caption = "Upgrades", direction = "vertical" }
		local upgradesTable = upgradeGui.add{ name = "upgradesTable", type = "table", column_count = 2 }
		for k,v in pairs(global.players[player.index].upgrades) do
			upgradesTable.add{ name = v.name, type = "label", caption = tostring(v.name) }
			upgradesTable.add{ name = v.name .. "_value", type = "label", caption = tostring(v.value) }
		end
		
	elseif guiName == "squadGui" then
		local squadGui = player.gui.top.rtsGui.add{ name = "squadGui", type = "frame", caption = "Squads", direction = "vertical" }
		local squadTable = squadGui.add{ name = "squadTable", type = "table", column_count = 3 }
		-- add table head
		local tableHeadColor = { r=1, g=.5, b=.5, a=1 }
		squadTable.add{ name = "squad_id", type = "label", caption = "squad id" }.style.font_color = tableHeadColor
		squadTable.add{ name = "squad_numMembers", type = "label", caption = "squad size" }.style.font_color = tableHeadColor
		squadTable.add{ name = "squad_preview", type = "label", caption = "preview" }.style.font_color = tableHeadColor
		
		-- fill table with squads
		local i = 0
		for squad, isInSet in pairs(global.players[player.index].squads) do

			if not isInSet then goto continue end
			if (not squad.valid) then 
				global.players[player.index].squads[squad] = nil 
				goto continue
			end
			if #squad.members == 0 then goto continue end
			local l1 = squadTable.add{ name = "squad_id_" .. i, type = "label", caption = "squad " .. i }
			local l2 = squadTable.add{ name = "squad_numMembers_" .. i, type = "label", caption = "" .. #squad.members }
			local fontColor = { r=1, g=1, b=1, a=1 }
			if squad == global.players[player.index].selectedSquad then
				fontColor = { r=.5, g=1, b=.5, a=1 }
			end
			l1.style.font_color = fontColor
			l2.style.font_color = fontColor
			local button = squadTable.add{ name = "squad_previewButton_" .. i, type = "button" }
			local preview = button.add{ name = "squad_preview_" .. i, type = "camera", position = squad.position, zoom = 0.25}
			button.style.minimal_height = 112
			button.style.minimal_width = 112
			preview.style.minimal_height = 100
			preview.style.minimal_width = 100
			preview.ignored_by_interaction = true
			-- game.print("i: "..i)
			i = i + 1
			::continue::
		end
	end
	]]
end

function Gui.Update_Gui(player, guiName)
	--[[
	if not player.gui.top.rtsGui[guiName] then return false end
	
	if guiName == "upgradeGui" then
	
		player.gui.top.rtsGui[guiName].destroy()
		Gui.Create_Gui(player, guiName)
		
	elseif guiName == "squadGui" then
	
		player.gui.top.rtsGui[guiName].destroy()
		Gui.Create_Gui(player, guiName)
		
	end
	]]
end

function Gui.Update_SquadGui_Tick(player)
	--[[
	local i = 0
	for squad, isInSet in pairs(global.players[player.index].squads) do
		if not isInSet then goto continue end
		if (not squad.valid) then 
			global.players[player.index].squads[squad] = nil 
			Gui.Update_Gui(player, "squadGui")
			return
		end
		if #squad.members == 0 then Gui.Update_Gui(player, "squadGui"); return end
		
		if 	not player.gui.top.rtsGui.squadGui or 
			not player.gui.top.rtsGui.squadGui.squadTable["squad_previewButton_" .. i] then 
			goto continue 
		end
		local fontColor = { r=1, g=1, b=1, a=1 }
		if squad == global.players[player.index].selectedSquad then
			fontColor = { r=.5, g=1, b=.5, a=1 }
		end
		player.gui.top.rtsGui.squadGui.squadTable["squad_id_" .. i].style.font_color = fontColor
		player.gui.top.rtsGui.squadGui.squadTable["squad_numMembers_" .. i].style.font_color = fontColor
		player.gui.top.rtsGui.squadGui.squadTable["squad_previewButton_" .. i]["squad_preview_" .. i].position = squad.position
		
		i = i + 1
		::continue::
	end
	]]
end

function Gui.Toggle_Gui(player, guiName)
	if player.gui.top.rtsGui[guiName] ~= nil then
		player.gui.top.rtsGui[guiName].destroy()
	else
		Gui.Create_Gui(player, guiName)
	end
end

function Gui.Create_RtsButton(player)
	if not player.gui.top.rtsGui then
		local rtsGui = player.gui.top.add{ name = "rtsGui", type = "flow", direction = "vertical" }
		
		local topRow = rtsGui.add{ name = "topRow", type = "flow", direction = "horizontal" }
		
		local button = topRow.add { name = "RtsButton", type = "sprite-button", sprite = "entity/small-biter" }
		button.style.font = "default-bold"
		button.style.minimal_height = 38
		button.style.minimal_width = 38
		button.style.top_padding = 2
		button.style.left_padding = 4
		button.style.right_padding = 4
		button.style.bottom_padding = 2
		
		local button = topRow.add { name = "UpgradeMenuButton", type = "sprite-button", sprite = "item-group/fluids", tooltip = "Upgrades" }
		button.style.font = "default-bold"
		button.style.minimal_height = 38
		button.style.minimal_width = 38
		button.style.top_padding = 2
		button.style.left_padding = 4
		button.style.right_padding = 4
		button.style.bottom_padding = 2
		
		Gui.Create_Gui(player, "upgradeGui")
	end
end

return Gui
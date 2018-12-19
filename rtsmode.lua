--[[============================================================================= 
#  Author:          Snoetje & exabyte
#  FileName:        rtsmode.lua
#  Description:     Rts Soft mod
#  Version:         1.1
#  LastChange:      2018-11-30
#  History:         
=============================================================================--]]

require 'config'

function IsRtsModeEnabled(player_index)
	return global.players[player_index].isRtsMode
end

local function BackupPlayer(player_index)
    local player = game.players[player_index]
	-- Make a backup
	global.players[player.index].nameBackup = player.name
	global.players[player.index].colorBackup = player.color
	
	--Remove name and make player dot opaque
	player.name = " "
	player.color = {r=0.0, g=0.0, b=0.0, a=0.0}
end

local function RestorePlayer(player)
    local player = game.players[player_index]
	player.name = global.players[player.index].nameBackup
	player.color = global.players[player.index].colorBackup
end

local function GiveSquadSelectTools(player_index)
    local quickbar = game.players[player_index].get_quickbar()
    for i = 1,10,1 
    do 
        quickbar.set_filter(i,"deconstruction-planner")
        game.players[player_index].insert{name="deconstruction-planner", count = 1}
        for x = 1,i,1 
        do
            quickbar[i].set_entity_filter(x,"fish")
        end
    end
end

function SetRtsMode(player_index, state)
    if state == true then
        global.players[player_index].isRtsMode = true

        game.players[player_index].character.destroy()
        game.print(player_index)
        GiveSquadSelectTools(player_index)

        -- BackupPlayer(player)
    elseif state == false then
        global.players[player_index].isRtsMode = false
    
        game.players[player_index].create_character()

        --RestorePlayer(player)
    end
end

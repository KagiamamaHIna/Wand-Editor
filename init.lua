dofile_once("mods/world_editor/files/gui/update.lua")
dofile_once( "data/scripts/lib/utilities.lua" );

local gui = GuiCreate()
function  OnPlayerSpawned(player)
    if not GameHasFlagRun("world_editor_init") then
        GameAddFlagRun("world_editor_init")
    end
end


function OnWorldPostUpdate()
	GUIUpdata()
end

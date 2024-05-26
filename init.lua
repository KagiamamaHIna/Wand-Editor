dofile_once("mods/wand_editor/files/libs/unsafe.lua")
dofile_once("mods/wand_editor/files/gui/update.lua")
dofile_once( "data/scripts/lib/utilities.lua" );

local gui = GuiCreate()
function  OnPlayerSpawned(player)
    if not GameHasFlagRun("world_editor_init") then
        GameAddFlagRun("world_editor_init")
    end
end

--TestAMonitor = Cpp.OpenMonitorLoadLuaLib(0x85AF1E)--非dev版为0x7ECD84

function OnWorldPostUpdate()
	GUIUpdata()
end

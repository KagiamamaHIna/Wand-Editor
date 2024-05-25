dofile_once("mods/world_editor/files/libs/unsafe.lua")
dofile_once("mods/world_editor/files/gui/update.lua")
dofile_once( "data/scripts/lib/utilities.lua" );

local gui = GuiCreate()
function  OnPlayerSpawned(player)
    if not GameHasFlagRun("world_editor_init") then
        GameAddFlagRun("world_editor_init")
		EntityLoadChild(player,"mods/world_editor/files/gui/test.xml")
    end
end

--TestAMonitor = Cpp.OpenMonitorLoadLuaLib(0x85AF1E)--非dev版为0x7ECD84

function OnWorldPostUpdate()
	GUIUpdata()
end

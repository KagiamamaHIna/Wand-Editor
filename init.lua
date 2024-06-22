dofile_once("mods/wand_editor/files/libs/unsafe.lua")
dofile_once("mods/wand_editor/files/libs/fn.lua")
dofile_once("mods/wand_editor/files/gui/update.lua")
dofile_once("data/scripts/lib/utilities.lua")

local SrcCsv = ModTextFileGetContent("data/translations/common.csv")--设置新语言文件
local AddCsv = ModTextFileGetContent("mods/wand_editor/files/lang/lang.csv")
ModTextFileSetContent("data/translations/common.csv", SrcCsv .. AddCsv)

local cachePath = Cpp.CurrentPath() .. "/mods/wand_editor/cache"
if not Cpp.PathExists(cachePath) then
	Cpp.CreateDir(cachePath)
end

function OnPlayerSpawned(player)
    if not GameHasFlagRun("world_editor_init") then
        GameAddFlagRun("world_editor_init")
    end
end
--TestAMonitor = Cpp.OpenMonitorLoadLuaLib(0x85AF1E)--非dev版为0x7ECD84

function OnWorldPostUpdate()
    GUIUpdata()
end

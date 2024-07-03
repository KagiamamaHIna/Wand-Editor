dofile_once("mods/wand_editor/files/libs/unsafe.lua")
dofile_once("mods/wand_editor/files/libs/fn.lua")
dofile_once("mods/wand_editor/files/gui/update.lua")
dofile_once("mods/wand_editor/files/libs/githubmirror.lua")
dofile_once("data/scripts/lib/utilities.lua")

ModLuaFileAppend("data/scripts/gun/gun.lua", "mods/wand_editor/files/append/gun.lua")
--[[
___ReWandStack = {}
___WandStack = {}
]]
local SrcCsv = ModTextFileGetContent("data/translations/common.csv")--设置新语言文件
local AddCsv = ModTextFileGetContent("mods/wand_editor/files/lang/lang.csv")
ModTextFileSetContent("data/translations/common.csv", SrcCsv .. AddCsv)
--[[测试用，删去注释后每次启动游戏都将删除所有的法杖仓库
ModSettingRemove(ModID.."WandDepotSize")
]]
if ModSettingGet(ModID .. "WandDepotSize") == nil then
    ModSettingSet(ModID .. "WandDepotSize", 0)
end
local https = require("ssl.https")

local r = {https.request(CurrentMirror("/KagiamamaHIna/Wand-Editor/main/files/libs/define.lua"))}
print("https:", unpack(r))

local cachePath = Cpp.CurrentPath() .. "/mods/wand_editor/cache"
if not Cpp.PathExists(cachePath) then
	Cpp.CreateDir(cachePath)
end

function OnPlayerSpawned(player)
	RestoreInput()--防止笨蛋在一些情况下重启游戏
    if not GameHasFlagRun("wand_editor_init") then
        EntityLoadChild(player, "mods/wand_editor/files/entity/Restore.xml")
        EntityAddComponent2(player, "LuaComponent", { script_shot = "mods/wand_editor/files/misc/self/player_shot.lua" })
        GameAddFlagRun("wand_editor_init")
    end
end

--GUI绘制
function OnWorldPostUpdate()
    GUIUpdate()
end

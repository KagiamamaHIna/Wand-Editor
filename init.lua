dofile_once("mods/wand_editor/files/libs/unsafe.lua")
dofile_once("mods/wand_editor/files/libs/fn.lua")
dofile_once("mods/wand_editor/files/gui/update.lua")
dofile_once("data/scripts/lib/utilities.lua")

ModLuaFileAppend("data/scripts/gun/gun.lua", "mods/wand_editor/files/append/gun.lua")

local SrcCsv = ModTextFileGetContent("data/translations/common.csv")--设置新语言文件
local AddCsv = ModTextFileGetContent("mods/wand_editor/files/lang/lang.csv")
ModTextFileSetContent("data/translations/common.csv", SrcCsv .. AddCsv)
--[[测试用，删去注释后每次启动游戏都将删除所有的法杖仓库
ModSettingRemove(ModID.."WandDepotSize")
]]
if ModSettingGet(ModID .. "WandDepotSize") == nil then
    ModSettingSet(ModID .. "WandDepotSize", 0)
end

if ModSettingGet(ModID..".remove_fog_of_war") then
    local src = ModTextFileGetContent("data/shaders/post_final.vert")
	ModTextFileSetContent("data/shaders/post_final.vert", string.gsub(src,"const float FOG_PIXEL_SIZE = 32.0;","const float FOG_PIXEL_SIZE = 0.0;"))
end
if ModSettingGet(ModID..".remove_lighting") then
    local src = ModTextFileGetContent("data/shaders/post_final.frag")
	ModTextFileSetContent("data/shaders/post_final.frag", string.gsub(src,"const bool ENABLE_LIGHTING	    		= 1>0;","const bool ENABLE_LIGHTING	    		= 1>2;"))
end
local cachePath = Cpp.CurrentPath() .. "/mods/wand_editor/cache"
if not Cpp.PathExists(cachePath) then
    Cpp.CreateDir(cachePath)
end

if not Cpp.PathExists(cachePath.."/yukimi") then
	Cpp.CreateDir(cachePath.."/yukimi")
end

function OnPlayerSpawned(player)
	RestoreInput()--防止笨蛋在一些情况下重启游戏
	ModSettingSet(ModID .. "hasButtonMove", false)
    if not GameHasFlagRun("wand_editor_init") then
        GameAddFlagRun("wand_editor_init")
        EntityLoadChild(player, "mods/wand_editor/files/entity/Restore.xml")
        EntityAddComponent2(player, "LuaComponent", { script_shot = "mods/wand_editor/files/misc/self/player_shot.lua" })
        EntityLoad("mods/wand_editor/files/biome_impl/wand_lab/wand_lab.xml", 12200, -5900)
        ModSettingSet(ModID .. "SpellLab", false)
		--初始化关于重置实验室的东西
		if Cpp.PathExists("mods/wand_editor/files/biome_impl/wand_lab/reset") then
			local t = Cpp.GetDirectoryPath("mods/wand_editor/files/biome_impl/wand_lab/reset")
            Cpp.Rename(t.File[1], "mods/wand_editor/files/biome_impl/wand_lab/reset/0")
        else
            Cpp.CreateDir("mods/wand_editor/files/biome_impl/wand_lab/reset")
            local png = io.open("mods/wand_editor/files/biome_impl/wand_lab/wang.png", "rb")
			io.input(png)
			local file = io.open("mods/wand_editor/files/biome_impl/wand_lab/reset/0", "wb") --将新内容写进文件中
			file:write(io.read("*a"))
            file:close()
			io.close(png)
		end
		if Cpp.PathExists("mods/wand_editor/files/biome_impl/wand_lab/reset_xml") then
			local t = Cpp.GetDirectoryPath("mods/wand_editor/files/biome_impl/wand_lab/reset_xml")
			Cpp.Rename(t.File[1], "mods/wand_editor/files/biome_impl/wand_lab/reset_xml/0")
        else
			Cpp.CreateDir("mods/wand_editor/files/biome_impl/wand_lab/reset_xml")
            local str = ReadFileAll("mods/wand_editor/files/biome_impl/wand_lab/overwrite.xml")
			local file = io.open("mods/wand_editor/files/biome_impl/wand_lab/reset_xml/0", "w") --将新内容写进文件中
			file:write(str)
			file:close()
		end

    end
end

--GUI绘制
function OnWorldPostUpdate()
    GUIUpdate()
end

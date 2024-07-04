dofile_once("mods/wand_editor/files/libs/define.lua")

SavePath = "%userprofile%/AppData/LocalLow/Nolla_Games_Noita/"

if DebugMode then
	package.cpath = package.cpath..";./"..ModDir.."files/module/debug/?.dll"
else
	package.cpath = package.cpath..";./"..ModDir.."files/module/?.dll"
end
package.cpath = package.cpath .. ";./" .. ModDir .. "files/module/socket/?.dll"
package.cpath = package.cpath .. ";./" .. ModDir .. "files/module/socket/mime/?.dll"--mime，lua socker运行依赖
package.path = package.path .. ";./" .. ModDir .. "files/socket_lua/?.lua"
package.path = package.path .. ";./" .. ModDir .. "files/socket_lua/socket/?.lua"
package.path = package.path .. ";./" .. ModDir .. "files/link/?.lua"
Cpp = require("WandEditorDll")--加载模块
Cpp.SetDllDirectory(Cpp.CurrentPath().."/mods/wand_editor/files/module/openssl")--提供openssl的动态链接库加载索引
effil = require("effil")
--初始化为绝对路径
SavePath = Cpp.GetAbsPath(SavePath)

---读取整个文件
---@param path string
---@return string
function ReadFileAll(path)
    local resultCache = {}
	local cacheCount = 1
    for v in io.lines(path) do
        resultCache[cacheCount] = v
        resultCache[cacheCount + 1] = '\n'
        cacheCount = cacheCount + 2
    end
    return table.concat(resultCache)
end

dofile_once("data/scripts/gun/gun_enums.lua")
dofile_once("data/scripts/status_effects/status_list.lua")
SpellTypeBG = {
	[ACTION_TYPE_PROJECTILE] = "data/ui_gfx/inventory/item_bg_projectile.png",
	[ACTION_TYPE_STATIC_PROJECTILE] = "data/ui_gfx/inventory/item_bg_static_projectile.png",
	[ACTION_TYPE_MODIFIER] = "data/ui_gfx/inventory/item_bg_modifier.png",
	[ACTION_TYPE_DRAW_MANY] = "data/ui_gfx/inventory/item_bg_draw_many.png",
	[ACTION_TYPE_MATERIAL] = "data/ui_gfx/inventory/item_bg_material.png",
	[ACTION_TYPE_OTHER] = "data/ui_gfx/inventory/item_bg_other.png",
	[ACTION_TYPE_UTILITY] = "data/ui_gfx/inventory/item_bg_utility.png",
	[ACTION_TYPE_PASSIVE] = "data/ui_gfx/inventory/item_bg_passive.png"
}
StatusMap = {}
for k,v in pairs(status_effects)do
	StatusMap[v.id] = k+1
end

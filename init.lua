--应当在这里做更新检查
--文件夹路径与文件是包含关系
--先删除文件夹路径，再删除文件
--一个应为删除路径，一个为新路径
--设置和init，unsafeFn.lua 需要预更新
dofile_once("mods/wand_editor/unsafeFn.lua")
local function fileExists(filepath)
    local file = io.open(filepath, "r") -- 尝试以只读模式打开文件
    if file then
        file:close() -- 如果文件打开成功，关闭文件
        return true  -- 文件存在
    else
        return false -- 文件不存在
    end
end
local flag = fileExists("mods/wand_editor/cache/UpdateFlag")
local flag2 = fileExists("mods/wand_editor/cache/PreDeletePaths.lua")
local flag3 = fileExists("mods/wand_editor/cache/NewPaths.lua")
if flag and flag2 and flag3 then
    UpdateFlag = true
end
local deldata
if UpdateFlag then
	local DelCode = ReadFileAll("mods/wand_editor/cache/PreDeletePaths.lua")
    local updateCode = ReadFileAll("mods/wand_editor/cache/NewPaths.lua")
    deldata = loadstring(DelCode)()
    local updateData = loadstring(updateCode)()
    for k, v in pairs(updateData.File) do --覆写文件
        RewriteBinFile(updateData.O_File[k], v)
    end
end
dofile_once("mods/wand_editor/proxied_init.lua")--加载真正的init.lua
if UpdateFlag then--移除多余文件
    for _, v in pairs(deldata) do
        Cpp.RemoveAll(v)
    end
	Cpp.RemoveAll("mods/wand_editor/cache/UpdateFlag")
    Cpp.RemoveAll("mods/wand_editor/cache/wand_editor")
    Cpp.RemoveAll("mods/wand_editor/cache/SpellsData.lua")
    Cpp.RemoveAll("mods/wand_editor/cache/TypeToSpellList.lua")
    Cpp.RemoveAll("mods/wand_editor/cache/ModEnable.lua")
    Cpp.RemoveAll("mods/wand_editor/cache/PreDeletePaths.lua")
	Cpp.RemoveAll("mods/wand_editor/cache/NewPaths.lua")
end

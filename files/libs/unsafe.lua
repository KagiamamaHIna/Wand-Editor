dofile_once("mods/wand_editor/files/libs/define.lua")

SavePath = "%userprofile%/AppData/LocalLow/Nolla_Games_Noita/"

if DebugMode then
	package.cpath = package.cpath..";./"..ModDir.."files/module/debug/?.dll"
else
	package.cpath = package.cpath..";./"..ModDir.."files/module/?.dll"
end

Cpp = require("WandEditorDll")--加载模块

--初始化为绝对路径
SavePath = Cpp.GetAbsPath(SavePath)

---读取整个文件
---@param path string
---@return string
function ReadFileAll(path)
    local resultCache = {}
    for v in io.lines(path) do
        table.insert(resultCache, v)
        table.insert(resultCache,'\n')
    end
    return table.concat(resultCache)
end

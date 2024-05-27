---返回软件本身的路径
---@return string
function Cpp.CurrentPath()end

---返回某一路径下的所有文件夹和文件
---@param path string
---@return table
function Cpp.GetDirectoryPath(path)end

---返回某一路径下的所有文件夹和文件以及其子文件夹和子文件
---@param path string
---@return table
function Cpp.GetDirectoryPathAll(path)end

---可以通过解析系统变量，返回一个绝对路径
---@param path string
---@return string
function Cpp.GetAbsPath(path)end

---不知道该怎么描述
---@param address integer
function Cpp.OpenMonitorLoadLuaLib(address)end

---返回路径下的文件名
---@param path string
---@return string
function Cpp.PathGetFileName(path)end

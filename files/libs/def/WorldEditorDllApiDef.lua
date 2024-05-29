---@diagnostic disable: missing-return
---返回软件本身的绝对路径
---@return string
function Cpp.CurrentPath()end

---返回某一绝对路径下的所有文件夹和文件
---@param path string
---@return table
function Cpp.GetDirectoryPath(path)end

---返回某一绝对路径下的所有文件夹和文件以及其子文件夹和子文件
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

---返回绝对路径下是否存在文件或文件夹
---@param path string
---@return boolean
function Cpp.PathExists(path)end

---创建一个路径，返回的是 是否创建成功
---@param path string
---@return boolean
function Cpp.CreateDir(path)end

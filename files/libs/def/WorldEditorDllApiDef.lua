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

---可以通过解析系统变量，返回一个绝对路径
---@param path string
---@return string
function Cpp.GetAbsPath(path)end

---不知道该怎么描述
---@param address integer
function Cpp.OpenMonitorLoadLuaLib(address)end

---计算两个字符串的相似程度。区间[0,100]
---@param s1 string
---@param s2 string
---@return number
function Cpp.Ratio(s1,s2)end

---计算一个字符串和另一个字符串的部分相似程度，比如"ab"和"abc"返回100。区间[0,100]
---@param s1 string
---@param s2 string
---@return number
function Cpp.PartialRatio(s1,s2)end

---用于计算拼音或原始字符串的匹配相似度。区间[0,100]，s1为输入的带中文的字符串，s2为输入的拼音字符串，s2不会进行转拼音匹配
---@param s1 string
---@param s2 string
---@return number
function Cpp.PinyinRatio(s1,s2)end

---用于计算拼音或原始字符串的匹配相似度。区间[0,100]，s1为输入的带中文的字符串，s2为输入的拼音字符串，s2不会进行转拼音匹配，如果s2为s1(或拼音)的子串，则返回值才会>0，否则是0，因此它返回值大于0都是绝对包含的
---@param s1 string
---@param s2 string
---@return number
function Cpp.AbsPartialPinyinRatio(s1,s2)end

---返回utf8编码格式的字符串的长度
---@param s1 string
---@return integer
function Cpp.UTF8StringSize(s1)end

---类似string.sub，区别是根据utf8编码进行分割操作
---@param str string
---@param pos1 integer
---@param pos2 integer
---@return string
function Cpp.UTF8StringSub(str,pos1,pos2)end

---设置剪切板的新内容，返回的为 是否设置成功
---@param str string
---@return boolean
function Cpp.SetClipboard(str)end

---获得剪切板的内容，如果不存在之类的为一个""
---@return string
function Cpp.GetClipboard()end

---同windows api SetDllDirectoryA
---@param str string
---@return boolean
function Cpp.SetDllDirectory(str) end

---std::rename的封装，返回0是成功，理论上还可用于移动文件
---@param old_filename string
---@param new_filename string
---@return integer
function Cpp.Rename(old_filename, new_filename)end

---拼接字符串
---@param ... string
---@return string
function Cpp.ConcatStr(...)end

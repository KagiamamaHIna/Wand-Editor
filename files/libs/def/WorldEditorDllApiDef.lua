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

---递归的创建一个路径，返回的是 是否创建成功。这个可以创建嵌套路径
---@param path string
---@return boolean
function Cpp.CreateDirs(path)end

---可以通过解析系统变量，返回一个绝对路径
---@param path string
---@return string
function Cpp.GetAbsPath(path)end

---加载Lua标准库至所有lua栈
function Cpp.LoadStandardForAllLua()end

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

--返回一个按utf8字符分割的字符串数组，比如"ABC"，返回{"A", "B", "C"}
---@param str string
---@return table
function Cpp.UTF8StringChars(str)end

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

---std::filesystem::remove的封装
---@param path string
---@return boolean
function Cpp.Remove(path)end

---std::filesystem::remove_all的封装
---@param path string
---@return number
function Cpp.RemoveAll(path)end

---拼接字符串
---@param ... string
---@return string
function Cpp.ConcatStr(...)end

---读取图片垂直翻转和水平翻转后再写入到指定路径
---@param FileStr string
---@param WritePath string
function Cpp.FlipImageLoadAndWrite(FileStr,WritePath)end

---同windows api int system(const char* command)
---@param command string
---@return integer
function Cpp.System(command)end

---解压文件到指定路径，返回的是：是否解压成功
---@param zip string
---@param outputPath string
---@return boolean
function Cpp.Uncompress(zip, outputPath)end

---@class BoolPTR lightuserdata

---@class IntPTR lightuserdata

---new一个bool指针，以lightuserdata的形式返回出来，如果不填写参数就不会初始化
---@param value boolean?
---@return BoolPTR
function Cpp.NewBoolPtr(value)end

---获取bool指针所指向的值
---@param ptr BoolPTR
---@return boolean
function Cpp.GetBoolPtrV(ptr)end

---设置bool指针所指向的值
---@param ptr BoolPTR
---@param value boolean
function Cpp.SetBoolPtrV(ptr,value)end

---new一个int指针，以lightuserdata的形式返回出来，如果不填写参数就不会初始化
---@param value integer?
---@return IntPTR
function Cpp.NewIntPtr(value)end

---获取int指针所指向的值
---@param ptr IntPTR
---@return integer
function Cpp.GetIntPtrV(ptr)end

---设置int指针所指向的值
---@param ptr IntPTR
---@param value integer
function Cpp.SetIntPtrV(ptr,value)end

---释放内存
---@param ptr IntPTR|BoolPTR
function Cpp.Free(ptr)end

---把ANSI编码转成utf8
---@param str string
---@return string
function Cpp.ANSIToUTF8(str)end

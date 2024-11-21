--这个文件大概率不会更新了

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

---参数1是被覆写的文件路径，参数2是用于覆写的文件路径
---@param filePath string
---@param path string
function RewriteBinFile(filePath, path)
    local GetPathFile = io.open(path, "rb")
    local allData = GetPathFile:read("*a")
    local file = io.open(filePath, "wb")
	file:write(allData)
    GetPathFile:close()
	file:close()
end

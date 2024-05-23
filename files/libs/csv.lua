---解析器

---@param str string
function ParseCSV(str)
    local cellDatas = {}
    local rowHeads = {}
    local cellArrangement = {}
    local result
    local tempKey = nil
    ---设置指定行列单元格的值
    ---* 使用行列号(从1开始的数字)来作为索引
    ---* 不存在的单元格会自动新建
    ---@param row number
    ---@param column number
    local set = function(row, column, value)
        if column == 1 then
            cellDatas[value] = {}
            table.insert(cellArrangement, value)
            tempKey = value
        end
        table.insert(cellDatas[tempKey], value)
        if row == 1 then rowHeads[value] = column end
    end
    result = {
        rowHeads = rowHeads,
        cellDatas = cellDatas,
        cellArrangement = cellArrangement,
        ---获取key对应值
        ---@param row string
        ---@param column string
        ---@return string|nil
        get = function(row, column)
            -- 尝试转为数字索引
            column = rowHeads[column]
            row = cellDatas[row]
            if column and row then
                local result = row[column]                                                          -- 34为"符号
                if string.byte(result, 1, 1) == 34 and string.byte(result, #result, #result) == 34 then --删除开头和结尾的" 因为实际游戏中也不存在
                    return string.sub(result, 2, string.len(result) - 1)
                end
                return result
            else
                return nil
            end
        end,
        tostring = function ()
            local cache = {}
            local newRowHeads = {}
            for v,k in pairs(rowHeads)do
                newRowHeads[k] = v
            end
            local rowHeadSize = #newRowHeads

            for i=1,rowHeadSize do
                if newRowHeads[i] ~= "" then
                    table.insert(cache,newRowHeads[i])
                end
                if i ~= rowHeadSize then
                    table.insert(cache,",")
                end
            end
            local cellSize = #cellArrangement
            for i=1,cellSize do
                local key = cellArrangement[i]
                local value = cellDatas[key]
                local size = #value
                for v_i,vstr in pairs(value)do--解析数组
                    if vstr ~= "" then
                        table.insert(cache,vstr)--插入字符串 
                    end
                    if v_i ~= size then--防止最后一个插入,
                        table.insert(cache,",")
                    end
                end
                if i ~= cellSize then--防止最后一个插入\n
                    table.insert(cache,"\n")--插入换行符
                end
            end
            return table.concat(cache)
        end
    }
    local state_quotationMark = false -- 双引号状态机
    local usub = string.sub
    local codepoint = string.byte
    local StartPos = 1 --用于记录一个需要被剪切的字符串的起始位
    local charNum = 0
    local posRow = 1
    local posColumn = 1
    for i = 1, #str do
        charNum = codepoint(str, i, i)
        if state_quotationMark then            -- 处于双引号包裹中
            state_quotationMark = (charNum ~= 34) --减少分支优化
        	if charNum == 92 then --转义符考虑
        		i = i + 1 --当前字符是转义符，下一个字符也应该跳过，所以加1，下一次循环再加1
        	end
        else
            if charNum == 34 then                                     -- 34为"符号
                state_quotationMark = true                            -- 进入双引号包裹
            elseif charNum == 44 then                                 -- 分隔符为en逗号 44为,
                set(posRow, posColumn, usub(str, StartPos, i - 1)) --i-1是为了不要把,加进去
                StartPos = i + 1                                      --重设起始位
                posColumn = posColumn + 1
            elseif charNum == 10 then                                 --10为\n
                -- 对连续换行(空行)和"\n"(Windows换行符)特殊处理
                if (codepoint(str, i - 1, i - 1) ~= 10) then
                    set(posRow, posColumn, usub(str, StartPos, i - 1))
                    StartPos = i + 1
                    posRow = posRow + 1
                    posColumn = 1
                end
            end
        end
    end
    set(posRow, posColumn, usub(str, StartPos, #str - 1))
    return result
end

return ParseCSV

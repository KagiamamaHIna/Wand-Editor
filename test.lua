---文件名意思为Functional programming

---打印一个表
---@param t table
function TablePrint(t)
    local print_r_cache = {}
    local function sub_print_r(t, indent)
        if (print_r_cache[tostring(t)]) then
            print(indent .. "*" .. tostring(t))
        else
            print_r_cache[tostring(t)] = true
            if (type(t) == "table") then
                for pos, val in pairs(t) do
                    if (type(val) == "table") then
                        print(indent .. "[" .. pos .. "] : " .. tostring(t) .. " {")
                        sub_print_r(val, indent .. string.rep(" ", string.len(pos) + 8))
                        print(indent .. string.rep(" ", string.len(pos) + 6) .. "}")
                    elseif (type(val) == "string") then
                        print(indent .. "[" .. pos .. '] : "' .. val .. '"')
                    else
                        print(indent .. "[" .. pos .. "] : " .. tostring(val))
                    end
                end
            else
                print(indent .. tostring(t))
            end
        end
    end
    if (type(t) == "table") then
        print(tostring(t) .. " {")
        sub_print_r(t, "  ")
        print("}")
    else
        sub_print_r(t, "  ")
    end
    print()
end

---内部函数，用于实现FnCompose
---@param a function
---@param b function
---@return function
local function fn2compose(a, b)
    return function(...)
        return b(a(...))
    end
end

---函数组合用，可以将多个函数组合 成一个
---@param ... function
---@return function
function FnCompose(...)
    local fns = { ... }
    local max = #fns
    local result = fns[1]
    if max > 1 then
        for i = 2, max do
            result = fn2compose(result, fns[i])
        end
    end
    return result
end


---柯里化函数
---@param func function
---@param numArgs integer
---@return function
function Curry(func, numArgs)
    --local numArgs = debug.getinfo(func, "u").nparams -- 获取原始函数的参数数量
    local function helper(accArgs, accCount)
        return function(...)
            local newArgs = { ... }
            if #newArgs == 0 and accCount == numArgs then
                return func(unpack(accArgs)) -- 如果参数数量足够，则执行函数
            else
                local combinedArgs = { unpack(accArgs) }
                for i = 1, #newArgs do
                    table.insert(combinedArgs, newArgs[i])
                end
                if #combinedArgs >= numArgs then
                    return func(unpack(combinedArgs)) -- 如果新参数使得数量足够，则执行函数
                else
                    return helper(combinedArgs, #combinedArgs)
                end
            end
        end
    end
    return helper({}, 0)
end

---@param num number
---@param decimalPlaces integer
---@return number
function TruncateFloat(num, decimalPlaces)
    local mult = 10^decimalPlaces
    return math.floor(num * mult) / mult
end

function Test(a, b, c)
    return a,b,c
end

print(TruncateFloat(12.12345,1))
--[[
function curry(func, num_args)
    -- 递归函数来收集参数
    local function helper(argtrace, n)
        if n < 1 then
            -- 收集完所有参数，调用原始函数
            return func(unpack(argtrace))
        else
            -- 返回一个新函数来收集下一个参数
            return function(nextarg)
                return helper({ nextarg, unpack(argtrace) }, n - 1)
            end
        end
    end
    -- 返回一个函数来开始收集参数
    return helper({}, num_args)
end
]]

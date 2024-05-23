---文件名意思为Functional programming

---函数组合用，可以将多个函数组合 成一个
---@param ... function
---@return function
function Compose(...)
    local function fn2compose(a,b)
        return function(...)
            return b(a(...))
        end
    end
    local fns = {...}
    local max = #fns
    local result = fns[max]
    if max > 1 then
        for i=max-1,1,-1 do
            result = fn2compose(result,fns[i])
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

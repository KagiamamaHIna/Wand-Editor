dofile_once("mods/world_editor/files/libs/fp.lua")
dofile_once("mods/world_editor/files/libs/define.lua")

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

---让指定小数位之后的规零
---@param num number
---@param decimalPlaces integer
---@return number
function TruncateFloat(num, decimalPlaces)
    local mult = 10^decimalPlaces
    return math.floor(num * mult) / mult
end

---如果为空则返回v（默认值），不为空返回本身的函数
---@param arg any
---@param v any
---@return any
function Default(arg, v)
    if arg == nil then
        return v
    end
    return arg
end

---帧转秒
---@param num number
---@return string
function FrToSecondStr(num)
    local temp = num / 60
    local result = string.format("%.2f",temp)
    return result
end

---获得Storage组件和对应值
---@param entity integer EntityID
---@param VariableName string
---@return any|nil
---@return integer|nil
function GetStorageComp(entity, VariableName)
    local comps = EntityGetComponent(entity, "VariableStorageComponent")
    if comps == nil then
        return
    end
    for _, comp in pairs(comps) do   --遍历存储组件表
        local name = ComponentGetValue2(comp, "name")
        if name == VariableName then --如果是状态就取值
            local value = ComponentGetValue2(comp, "value_int")
            return value, comp
        end
    end
end

---增加并设置Storage
---@param entity integer
---@param i_name string
---@param i_value any
---@return integer|nil
function AddSetStorageComp(entity, i_name, i_value)
    if entity == nil then
        return
    end
    return EntityAddComponent(entity, "VariableStorageComponent", { name = i_name, value_int = i_value })
end

---设置Storage，并返回组件
---@param entity integer
---@param VariableName string
---@param i_value any
---@return integer|nil
function SetStorageComp(entity, VariableName, i_value)
    local comps = EntityGetComponent(entity, "VariableStorageComponent")
    if comps == nil then
        return
    end
    for _, comp in pairs(comps) do   --遍历存储组件表
        local name = ComponentGetValue2(comp, "name")
        if name == VariableName then --如果是就取值
            ComponentSetValue2(comp, "value_int", i_value)
            return comp
        end
    end
end

---加载某路径的实体以子实体的形式加载到另一实体
---@param father integer EntityID
---@param path string EntityFile
---@return integer
function EntityLoadChild(father, path)
    local x, y = EntityGetTransform(father)
    local id = EntityLoad(path, x, y)
    EntityAddChild(father, id)
    return id
end

---返回一个实体其子实体有对应标签的数组
---@param entity integer EntityID
---@param tag string
---@return integer[]|nil
function EntityGetChildWithTag(entity, tag)
    local result
    local child = EntityGetAllChildren(entity)
    if child ~= nil then
        result = {}
        for _, v in pairs(child) do
            if EntityHasTag(v, tag) then
                table.insert(result, v)
            end
        end
    end
    return result
end

---获取当前拿着的法杖
---@param entity integer EntityID
---@return integer|nil
function GetEntityHeldWand(entity)
    local result
    local inventory2 = EntityGetFirstComponent(entity, "Inventory2Component")
    if inventory2 ~= nil then
        local active = ComponentGetValue2(inventory2, "mActiveItem");
        if EntityHasTag(active, "wand") then
            result = active
        end
    end
    return result
end

---获得玩家id
---@return integer
function GetPlayer()
    return EntityGetWithTag("player_unit")[1]
end

---获取法杖的法术id列表
---@param entity integer
---@return string[]
function GetWandSpellIDs(entity)
    local result = {}
    local Ability = EntityGetFirstComponentIncludingDisabled(entity, "AbilityComponent")
    local capacity = ComponentObjectGetValue2(Ability, "gun_config", "deck_capacity")
    for i = 1, capacity - 1 do
        table.insert(result, "nil")
    end

    local spellEntitys = EntityGetChildWithTag(entity, "card_action")
    if spellEntitys ~= nil then
        for _, v in pairs(spellEntitys) do
            local ItemActionComp = EntityGetFirstComponentIncludingDisabled(v, "ItemActionComponent")
            local ItemComp = EntityGetFirstComponentIncludingDisabled(v, "ItemComponent")
            local index = ComponentGetValue2(ItemComp, "inventory_slot")
            local spellid = ComponentGetValue2(ItemActionComp, "action_id")
            result[index] = spellid
        end
    end
    return result
end

---获得法杖数据
---@param entity integer EntityID
---@return table|nil
function GetWandData(entity)
    if EntityHasTag(entity, "wand") then
        local wand = {
            wandEntity = entity,
            spells = GetWandSpellIDs(entity), --法术表
            mana_charge_speed = nil,          --回蓝速度
            mana_max = nil,                   --蓝上限
            fire_rate_wait = nil,             --施放延迟
            reload_time = nil,                --充能延迟
            deck_capacity = nil,              --容量
            spread_degrees = nil,             --散射
            shuffle_deck_when_empty = nil,    --是否乱序
            sprite_file = nil,                --贴图
            speed_multiplier = nil,           --初速度加成
        }
        local Ability = EntityGetFirstComponentIncludingDisabled(entity, "AbilityComponent")
        local CompGetValue = Curry(ComponentGetValue2,2)(Ability)
        local GunConfigGetValue = Curry(ComponentObjectGetValue2,3)(Ability, "gun_config")
        local GunActionGetValue = Curry(ComponentObjectGetValue2,3)(Ability, "gunaction_config")

        wand.mana_max = CompGetValue("mana_max")
        wand.mana_charge_speed = CompGetValue("mana_charge_speed")
        wand.sprite_file = CompGetValue("sprite_file")
        wand.shuffle_deck_when_empty = GunConfigGetValue("shuffle_deck_when_empty")
        wand.deck_capacity = GunConfigGetValue("deck_capacity")
        wand.reload_time = GunConfigGetValue("reload_time")
        wand.spread_degrees = GunActionGetValue("spread_degrees")
        wand.fire_rate_wait = GunActionGetValue("fire_rate_wait")
        wand.speed_multiplier = GunActionGetValue("speed_multiplier")
        return wand
    end
    --print_error("GetWandData param1 not a wand")
end

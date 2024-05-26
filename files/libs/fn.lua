dofile_once("mods/world_editor/files/libs/fp.lua")
dofile_once("mods/world_editor/files/libs/define.lua")

local noita_print = print

---重新实现来模拟正确的print行为
---@param ... any
print = function(...)
	local cache = {}
	for _, v in pairs({ ... }) do
		table.insert(cache, tostring(v))
	end
	noita_print(table.concat(cache))
end

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

---序列化函数，将table转换成lua代码
---@param tbl table
---@param indent any|nil indent = ""
---@return string
function SerializeTable(tbl, indent)
	indent = Default(indent, "")
	local result = ""
	local is_array = #tbl > 0
	for k, v in pairs(tbl) do
		local key
		if is_array and type(k) == "number" then
			key = ""
		else
			key = k .. " = "
		end

		if type(v) == "table" then
			result = result .. string.format("%s%s{\n", indent, key)
			result = result .. SerializeTable(v, indent .. "    ")
			result = result .. string.format("%s},\n", indent)
		else
			result = result .. string.format("%s%s%q,\n", indent, key, v)
		end
	end
	return result
end

---让指定小数位之后的归零
---@param num number
---@param decimalPlaces integer
---@return number
function TruncateFloat(num, decimalPlaces)
	local mult = 10 ^ decimalPlaces
	return math.floor(num * mult) / mult
end

---帧转秒
---@param num number
---@return string
function FrToSecondStr(num)
	local temp = num / 60
	local result = string.format("%.2f", temp)
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


function GetEntityAllComponentMembers(eneity)
	local result = {}
	local CompIDs = EntityGetAllComponents(eneity)
	for _, id in pairs(CompIDs) do
		local Members = ComponentGetMembers(id)
		local name = ComponentGetTypeName(id)
		if Members ~= nil then
			result[name] = { Members = Members, CompID = id }
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
	if __PlayerIDCache == nil then
		__PlayerIDCache = EntityGetWithTag("player_unit")[1]
	end
	return __PlayerIDCache
end

---获取法杖的法术id列表
---@param entity integer
---@return table
function GetWandSpellIDs(entity)
	local result = { always = {}, spells = {} }
	local Ability = EntityGetFirstComponentIncludingDisabled(entity, "AbilityComponent")
	local capacity = ComponentObjectGetValue2(Ability, "gun_config", "deck_capacity")
	local spellList = {}
	local spellEntitys = EntityGetChildWithTag(entity, "card_action")
	local AlwaysCount = 0
	if spellEntitys ~= nil then
		for _, v in pairs(spellEntitys) do
			local ItemActionComp = EntityGetFirstComponentIncludingDisabled(v, "ItemActionComponent")
			local ItemComp = EntityGetFirstComponentIncludingDisabled(v, "ItemComponent")
			local isAlways = ComponentGetValue2(ItemComp, "permanently_attached")
			local index = ComponentGetValue2(ItemComp, "inventory_slot")
			local spellid = ComponentGetValue2(ItemActionComp, "action_id")
			local is_frozen = ComponentGetValue2(ItemComp, "is_frozen")
			table.insert(spellList, { isAlways = isAlways, index = index, id = spellid, is_frozen = is_frozen })
			if isAlways then
				AlwaysCount = AlwaysCount + 1
			end
		end
	end
	for _ = 1, capacity - AlwaysCount do
		table.insert(result.spells, "nil")
	end
	for _, v in pairs(spellList) do
		if v.isAlways then
			table.insert(result.always, v)
		else
			result.spells[v.index + 1] = v
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
			item_name = nil,
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
			mana = nil,                       --蓝
		}
		local Ability = EntityGetFirstComponentIncludingDisabled(entity, "AbilityComponent")
		local CompGetValue = Curry(ComponentGetValue2, 2)(Ability)
		local GunConfigGetValue = Curry(ComponentObjectGetValue2, 3)(Ability, "gun_config")
		local GunActionGetValue = Curry(ComponentObjectGetValue2, 3)(Ability, "gunaction_config")
		local item = EntityGetFirstComponentIncludingDisabled(entity, "ItemComponent");
		wand.item_name = ComponentGetValue2(item, "item_name")
		wand.mana_max = CompGetValue("mana_max")
		wand.mana_charge_speed = CompGetValue("mana_charge_speed")
		wand.mana = CompGetValue("mana")
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

---通过法杖数据初始化一根法杖并返回其实体id
---@param wandData table 由GetWandData函数自动生成
---@param wand integer|nil EntityID，当wand为nil的时候将自动生成一个实体用于加载魔杖
---@param x number? x = 0
---@param y number? y = 0
---@return integer
function InitWand(wandData, wand, x, y)
    if wand == nil then
        wand = EntityLoad("mods/world_editor/files/entity/wand_base.xml", x, y)
    end
	if not EntityGetIsAlive(wand) then
		return 0
	end
	local ability = EntityGetFirstComponentIncludingDisabled(wand, "AbilityComponent")
	local item = EntityGetFirstComponentIncludingDisabled(wand, "ItemComponent");
	local CompSetValue = Curry(ComponentSetValue2, 3)(ability)
	local GunConfigSetValue = Curry(ComponentObjectSetValue2, 4)(ability, "gun_config")
	local GunActionSetValue = Curry(ComponentObjectSetValue2, 4)(ability, "gunaction_config")
	--初始化数据
	ComponentSetValue2(item, "item_name", wandData.item_name)
	CompSetValue("mana_max", wandData.mana_max)
	CompSetValue("mana_charge_speed", wandData.mana_charge_speed)
	CompSetValue("mana", wandData.mana)
	CompSetValue("sprite_file", wandData.sprite_file)
	GunConfigSetValue("shuffle_deck_when_empty", wandData.shuffle_deck_when_empty)
	GunConfigSetValue("deck_capacity", wandData.deck_capacity)
	GunConfigSetValue("reload_time", wandData.reload_time)
	GunActionSetValue("spread_degrees", wandData.spread_degrees)
	GunActionSetValue("fire_rate_wait", wandData.fire_rate_wait)
    GunActionSetValue("speed_multiplier", wandData.speed_multiplier)
    local sprite = EntityGetFirstComponent(wand, "SpriteComponent", "item");
	if sprite ~= nil then--刷新贴图
        ComponentSetValue2(sprite, "image_file", wandData.sprite_file)
        EntityRefreshSprite(wand, sprite)
	end
	--初始化法术
    for _, v in pairs(wandData.spells) do
        for _, spell in pairs(v) do
            if spell.id and spell.id ~= "nil" then
                local action = CreateItemActionEntity(spell.id)
                local item = EntityGetFirstComponentIncludingDisabled(action, "ItemComponent")
                ComponentSetValue2(item, "permanently_attached", spell.isAlways)
                ComponentSetValue2(item, "is_frozen", spell.is_frozen)
                ComponentSetValue2(item, "inventory_slot", spell.index, 0)
                EntitySetComponentsWithTagEnabled(action, "enabled_in_world", false);
                EntityAddChild(wand, action);
            end
        end
    end
	return wand
end

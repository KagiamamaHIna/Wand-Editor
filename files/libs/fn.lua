dofile_once("mods/wand_editor/files/libs/fp.lua")
dofile_once("mods/wand_editor/files/libs/define.lua")

local noita_print = print

---重新实现来模拟正确的print行为
---@param ... any
print = function(...)
    local cache = {}
	local cacheCount = 1
    for _, v in pairs({ ... }) do
        cache[cacheCount] = v
		cacheCount = cacheCount + 1
	end
	noita_print(table.concat(cache))
end

local noita_game_print = GamePrint

--重新实现一个
---@param ... any
GamePrint = function(...)
    local cache = {}
	local cacheCount = 1
    for _, v in pairs({ ... }) do
        cache[cacheCount] = v
		cacheCount = cacheCount + 1
	end
	noita_game_print(table.concat(cache))
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

--- 序列化函数，将table转换成lua代码
---@param tbl table
---@param indent any|nil indent = ""
---@return string
function SerializeTable(tbl, indent)
    indent = indent or ""
    local result = ""
    local is_array = #tbl > 0 or tbl[0] ~= nil
    for k, v in pairs(tbl) do
        local key
        if is_array and type(k) == "number" then
            -- 当键名是数字时，使用中括号但不使用引号
            key = string.format("[%s] = ", k)
        else -- 当键名是字符串时，使用方括号和双引号
            key = string.format("[%q] = ", k)
        end

        if type(v) == "table" then
            result = result .. string.format("%s%s{\n", indent, key)
            result = result .. SerializeTable(v, indent .. "    ")
            result = result .. string.format("%s},\n", indent)
        elseif type(v) == "boolean" or type(v) == "number" then
            result = result .. string.format("%s%s%s,\n", indent, key, tostring(v))
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

---将[0,255]之间的整数转换成小数表示
---@param num number
---@return number
function ColorToDecimal(num)
    return num / 255
end

---不数小数，输入整数
---@param gui userdata
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function GuiRGBAColorSetForNextWidget(gui, red, green, blue, alpha)
    GuiColorSetForNextWidget(gui, ColorToDecimal(red), ColorToDecimal(green), ColorToDecimal(blue), ColorToDecimal(alpha))
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
	for _, comp in pairs(comps) do --遍历存储组件表
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
	for _, comp in pairs(comps) do --遍历存储组件表
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
		local resultCount = 1
		for _, v in pairs(child) do
            if EntityHasTag(v, tag) then
                result[resultCount] = v
				resultCount = resultCount + 1
			end
		end
	end
	return result
end

---返回一个实体其子实体有对应名字的数据
---@param entity integer EntityID
---@param name string
---@return integer|nil
function EntityGetChildWithName(entity, name)
	local child = EntityGetAllChildren(entity)
	if child ~= nil then
		for _, v in pairs(child) do
			if EntityGetName(v) == name then
				return v
			end
		end
	end
end

---获取当前拿着的法杖
---@param entity integer EntityID
---@return integer|nil
function GetEntityHeldWand(entity)
	local result
	local inventory2 = EntityGetFirstComponent(entity, "Inventory2Component")
	if inventory2 ~= nil then
		local active = ComponentGetValue2(inventory2, "mActiveItem");
		if EntityHasTag(active, "wand") then --如果是魔杖
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
	local result = { always = {}, spells = {}}
	local Ability = EntityGetFirstComponentIncludingDisabled(entity, "AbilityComponent")
	local capacity = ComponentObjectGetValue2(Ability, "gun_config", "deck_capacity")--容量
	local spellList = {}
    local spellEntitys = EntityGetChildWithTag(entity, "card_action")
    local AlwaysCount = 0--统计正确的容量用
	local IndexZeroCount = 0--有时候sb nolla不会初始化inventory_slot.x，导致全部都是0，这时候需要手动重新分配，并且计数
    if spellEntitys ~= nil then
        for _, v in pairs(spellEntitys) do
            local ItemActionComp = EntityGetFirstComponentIncludingDisabled(v, "ItemActionComponent")
            local ItemComp = EntityGetFirstComponentIncludingDisabled(v, "ItemComponent")
            local isAlways = ComponentGetValue2(ItemComp, "permanently_attached")
            local index = ComponentGetValue2(ItemComp, "inventory_slot")
            local spellid = ComponentGetValue2(ItemActionComp, "action_id")
            local is_frozen = ComponentGetValue2(ItemComp, "is_frozen")
            if index == 0 then--当索引为0的时候
				if IndexZeroCount > 0 then--判断数量
					index = IndexZeroCount
				end
				IndexZeroCount = IndexZeroCount + 1--自增
			end
            spellList[index+1] = { isAlways = isAlways, index = index, id = spellid, is_frozen = is_frozen }
            if isAlways then
                AlwaysCount = AlwaysCount + 1
            end
        end
    end
	for i=1,capacity - AlwaysCount do
		result.spells[i] = "nil"
	end
	--设置数据
	for k, v in pairs(spellList) do
		if v.isAlways then
			table.insert(result.always, v)
		else
            result.spells[k] = v
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
			mana_charge_speed = nil, --回蓝速度
			mana_max = nil,          --蓝上限
			fire_rate_wait = nil,    --施放延迟
			reload_time = nil,       --充能延迟
			deck_capacity = nil,     --容量
			spread_degrees = nil,    --散射
			shuffle_deck_when_empty = nil, --是否乱序
			speed_multiplier = nil,  --初速度加成
            mana = nil,              --蓝
			actions_per_round = nil, --施放数
            shoot_pos = { x = 0, y = 0 }, --发射位置
            sprite_file = nil,            --贴图
			sprite_pos = {x = 0, y = 0 }--精灵图偏移
		}
		local Ability = EntityGetFirstComponentIncludingDisabled(entity, "AbilityComponent")
		local CompGetValue = Curry(ComponentGetValue2, 2)(Ability)
		local GunConfigGetValue = Curry(ComponentObjectGetValue2, 3)(Ability, "gun_config")
		local GunActionGetValue = Curry(ComponentObjectGetValue2, 3)(Ability, "gunaction_config")
		local item = EntityGetFirstComponentIncludingDisabled(entity, "ItemComponent")
        local hotspot = EntityGetFirstComponentIncludingDisabled(entity, "HotspotComponent", "shoot_pos")
        local sprite = EntityGetFirstComponent(entity, "SpriteComponent", "item")
        wand.sprite_pos.x = ComponentGetValue2(sprite, "offset_x")
		wand.sprite_pos.y = ComponentGetValue2(sprite, "offset_y")
		wand.shoot_pos.x, wand.shoot_pos.y = ComponentGetValue2(hotspot, "offset") --发射偏移量
		wand.item_name = ComponentGetValue2(item, "item_name")

		wand.mana_max = CompGetValue("mana_max")
		wand.mana_charge_speed = CompGetValue("mana_charge_speed")
		wand.mana = CompGetValue("mana")
        wand.sprite_file = CompGetValue("sprite_file")
		wand.actions_per_round = GunConfigGetValue("actions_per_round")
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

---设置表中的一个法术，越界了就增加大小
---@param input table GetWandData函数的返回值
---@param id string
---@param index integer
---@param isAlways boolean?
function SetTableSpells(input, id, index, isAlways)
	if isAlways then--判断是不是始终释放
        --是
        table.insert(input.spells.always, { id = id, isAlways = true, is_frozen = false, index = index-1 })
    else                                           --不是
        if index > #input.spells.spells then
            for i = 1, index - #input.spells.spells do --如果索引超过的情况下，加额外数据
                input.deck_capacity = input.deck_capacity + 1
				input.spells.spells[#input.spells.spells + 1] = "nil"
            end
        end
        if input.spells.spells[index] == nil or input.spells.spells[index] == "nil" then
            input.spells.spells[index] = { id = id, index = index - 1, is_frozen = false, isAlways = false }
        else
            input.spells.spells[index].id = id
        end
	end
end

---交互两个法术的位置, 如果索引越界则什么都不做
---@param input table GetWandData函数的返回值
---@param pos1 integer
---@param pos2 integer
function SwapSpellPos(input, pos1, pos2)
	if input.spells.spells[pos1] == nil or input.spells.spells[pos2] == nil then
		return
	end
	if input.spells.spells[pos1] ~= "nil" and input.spells.spells[pos2] ~= "nil" then--两个都不为空
        --交互索引
		local oldIndex = input.spells.spells[pos1].index
        input.spells.spells[pos1].index = input.spells.spells[pos2].index
        input.spells.spells[pos2].index = oldIndex
		--交互表
        local oldTable = input.spells.spells[pos1]
        input.spells.spells[pos1] = input.spells.spells[pos2]
        input.spells.spells[pos2] = oldTable
    elseif input.spells.spells[pos1] == "nil" and input.spells.spells[pos2] ~= "nil" then
        input.spells.spells[pos2].index = pos1-1
        input.spells.spells[pos1] = input.spells.spells[pos2]
		input.spells.spells[pos2] = "nil"
	elseif input.spells.spells[pos2] == "nil" and input.spells.spells[pos1] ~= "nil" then
		input.spells.spells[pos1].index = pos2-1
        input.spells.spells[pos2] = input.spells.spells[pos1]
		input.spells.spells[pos1] = "nil"
	end
end

---重新设置一个容量大小，可增可减
---@param input table GetWandData函数的返回值
---@param size integer
function ResetDeckCapacity(input, size)
	if input.deck_capacity < size then --如果要设置成更大大小的
        for i=1,size-input.deck_capacity do
			input.spells.spells[#input.spells.spells + 1] = "nil"
		end
        input.deck_capacity = size
    elseif input.deck_capacity > size then--如果要设置成更小大小的
		for i=1,input.deck_capacity-size do
			input.spells.spells[#input.spells.spells] = "nil"
		end
        input.deck_capacity = size
	end--等于时啥也不干
end

---删除一个指定索引的法术，如果有的话
---@param input table GetWandData函数的返回值
function RemoveTableSpells(input, TableIndex)
	if input[TableIndex] then
		input.spells.spells[TableIndex] = "nil"
	end
end

---WIP
---@param input table GetWandData函数的返回值
function RemoveTableAlwaysSpells(input, TableIndex)
	
end

function UpdateWand(wandData,wand)
    local SWandData = GetWandData(wand)
	if SWandData then
		for k, v in pairs(wandData) do
			SWandData[k] = v --设置新的参数
		end
		return InitWand(SWandData,wand)
	end
end

---通过法杖数据初始化一根法杖并返回其实体id
---@param wandData table 由GetWandData函数自动生成
---@param wand integer|nil? EntityID，当wand为nil的时候将自动生成一个实体用于加载魔杖
---@param x number? x = 0
---@param y number? y = 0
---@return integer
function InitWand(wandData, wand, x, y)
	if wand == nil then
		wand = EntityLoad("mods/wand_editor/files/entity/WandBase.xml", x, y)
	end
	if not EntityGetIsAlive(wand) then
		return 0
	end
	local ability = EntityGetFirstComponentIncludingDisabled(wand, "AbilityComponent")
	local item = EntityGetFirstComponentIncludingDisabled(wand, "ItemComponent");
	local CompSetValue = Curry(ComponentSetValue2, 3)(ability)
	local GunConfigSetValue = Curry(ComponentObjectSetValue2, 4)(ability, "gun_config")
	local GunActionSetValue = Curry(ComponentObjectSetValue2, 4)(ability, "gunaction_config")
	local hotspot = EntityGetFirstComponentIncludingDisabled(wand, "HotspotComponent", "shoot_pos")
	--初始化数据
	ComponentSetValueVector2(hotspot, "offset", wandData.shoot_pos.x, wandData.shoot_pos.y)
	ComponentSetValue2(item, "item_name", wandData.item_name)
	CompSetValue("mana_max", wandData.mana_max)
	CompSetValue("mana_charge_speed", wandData.mana_charge_speed)
	CompSetValue("mana", wandData.mana)
	CompSetValue("sprite_file", wandData.sprite_file)
	GunConfigSetValue("shuffle_deck_when_empty", wandData.shuffle_deck_when_empty)
	GunConfigSetValue("deck_capacity", wandData.deck_capacity)
    GunConfigSetValue("reload_time", wandData.reload_time)
	GunConfigSetValue("actions_per_round", wandData.actions_per_round)
	GunActionSetValue("spread_degrees", wandData.spread_degrees)
	GunActionSetValue("fire_rate_wait", wandData.fire_rate_wait)
	GunActionSetValue("speed_multiplier", wandData.speed_multiplier)
	local sprite = EntityGetFirstComponent(wand, "SpriteComponent", "item")
    if sprite ~= nil then --刷新贴图
        ComponentSetValue2(sprite, "image_file", wandData.sprite_file)
        ComponentSetValue2(sprite, "offset_x", wandData.sprite_pos.x)
        ComponentSetValue2(sprite, "offset_y", wandData.sprite_pos.y)
        EntityRefreshSprite(wand, sprite)
    end
	--TablePrint(wandData)
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

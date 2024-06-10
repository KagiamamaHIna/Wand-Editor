dofile_once("mods/wand_editor/files/libs/fn.lua")
dofile_once("mods/wand_editor/files/libs/unsafe.lua")
dofile_once("data/scripts/gun/gun.lua")

---输入类型枚举量获得其对应的字符串
---@param type integer
---@return string
function SpellTypeEnumToStr(type)
	local TypeTable = {
		[ACTION_TYPE_PROJECTILE] = GameTextGetTranslatedOrNot("$inventory_actiontype_projectile"),
		[ACTION_TYPE_STATIC_PROJECTILE] = GameTextGetTranslatedOrNot("$inventory_actiontype_staticprojectile"),
		[ACTION_TYPE_MODIFIER] = GameTextGetTranslatedOrNot("$inventory_actiontype_modifier"),
		[ACTION_TYPE_DRAW_MANY] = GameTextGetTranslatedOrNot("$inventory_actiontype_drawmany"),
		[ACTION_TYPE_MATERIAL] = GameTextGetTranslatedOrNot("$inventory_actiontype_material"),
		[ACTION_TYPE_OTHER] = GameTextGetTranslatedOrNot("$inventory_actiontype_other"),
		[ACTION_TYPE_UTILITY] = GameTextGetTranslatedOrNot("$inventory_actiontype_utility"),
		[ACTION_TYPE_PASSIVE] = GameTextGetTranslatedOrNot("$inventory_actiontype_passive")
	}
    local result = TypeTable[type]
	if result ~= nil then
		return result
	end
	return "unknown"
end

---返回模组加载情况
---@return table<string, boolean>
local function GetModEnableList()
	local ModIdToEnable = {}
	local ModsPath = Cpp.GetDirectoryPath(Cpp.CurrentPath() .. "/mods/")
    for _, v in pairs(ModsPath.Path) do
        if Cpp.PathExists(v.."/mod.xml") then--判断是否存在，通过这个判断是否为一个模组
			local modid = Cpp.PathGetFileName(v)
			ModIdToEnable[modid] = ModIsEnabled(modid)
		end
    end
	return ModIdToEnable
end

--判断是否有缓存文件
local cachePath = Cpp.CurrentPath() .. "/mods/wand_editor/cache/"
local HasCahce = Cpp.PathExists(cachePath.."SpellsData.lua") and Cpp.PathExists(cachePath.."ModEnable.lua") and Cpp.PathExists(cachePath.."TypeToSpellList.lua")

--检查是否需要更新缓存
local ModIdToEnable = GetModEnableList()
if HasCahce then
    local UpModEnable = dofile_once("mods/wand_editor/cache/ModEnable.lua")
	local Change = false
    for k, v in pairs(ModIdToEnable) do
        if UpModEnable[k] == nil then --代表有新模组
            Change = ModIsEnabled(k)
			if Change then--如果启动了这个模组就退出
				break
			end
        elseif UpModEnable[k] ~= v then
            --代表模组变动
            Change = true
            break
        end
    end
	if not Change then--可以直接读取缓存！
		--print("Cache Get")
		local result1 = dofile_once("mods/wand_editor/cache/SpellsData.lua")
		local result2 = dofile_once("mods/wand_editor/cache/TypeToSpellList.lua")
		return {result1,result2}
	end
end
--print("Init Spell Data")
--需要重新加载
local result = {}

--监听的数据
current_reload_time = 0 --充能时间

c = {}
reset_modifiers(c)                      --初始化
shot_effects = {}
ConfigGunShotEffects_Init(shot_effects) --初始化

local CurrentID = nil
local hasProj = {}
draw_actions = function(draw)           --设置抽取数，当被调用时
	result[CurrentID].draw_actions = draw
end


reflecting = true
Reflection_RegisterProjectile = function(filepath)
	--获取投射物数据，判断是否有缓存
	if hasProj[filepath] == nil then
		local proj = EntityLoad(filepath, 14600, -45804)
		hasProj[filepath] = {}
		local projComp = EntityGetFirstComponent(proj, "ProjectileComponent")
        if projComp then
            local projXML = ParseXmlAndBase(filepath)
			for _,v in pairs(projXML.children)do
				if v.name == "ProjectileComponent" then
                    result[CurrentID].lifetime = v.attr.lifetime
                    hasProj[filepath].lifetime = result[CurrentID].lifetime
					break
				end
			end

			ComponentSetValue2(projComp, "on_death_explode", false)
			ComponentSetValue2(projComp, "on_lifetime_out_explode", false)
			ComponentSetValue2(projComp, "collide_with_entities", false)
			ComponentSetValue2(projComp, "collide_with_world", false)

			result[CurrentID].projComp = {}
			for k, v in pairs(ComponentGetMembers(projComp)) do --批量加载数据
				result[CurrentID].projComp[k] = v
			end
			hasProj[filepath].projComp = result[CurrentID].projComp

			--接下来要从object中手动获得值
			local damage_by_type = ComponentObjectGetMembers(projComp, "damage_by_type")
			if damage_by_type ~= nil then
				result[CurrentID].projDmg = {}
				for k, v in pairs(damage_by_type) do
					result[CurrentID].projDmg[k] = tonumber(v)
				end

				hasProj[filepath].projDmg = result[CurrentID].projDmg
			end
			local config_explosion = ComponentObjectGetMembers(projComp, "config_explosion")
			if config_explosion ~= nil then
				result[CurrentID].projExplosion = tonumber(ComponentObjectGetValue2(projComp, "config_explosion", "damage"))
                hasProj[filepath].projExplosion = result[CurrentID].projExplosion
				result[CurrentID].projExplosionRadius = tonumber(ComponentObjectGetValue2(projComp, "config_explosion", "explosion_radius"))
				hasProj[filepath].projExplosionRadius = result[CurrentID].projExplosionRadius
			end
		end
		--杀死实体
		EntityKill(proj)
	else
		--读取缓存
		for k, v in pairs(hasProj[filepath]) do
			result[CurrentID][k] = v
		end
	end
end

local player = GetPlayer()
EntityRemoveTag(player, "player_unit")

local TypeToSpellListCount = {}

local TypeToSpellList = {}
TypeToSpellList.AllSpells = {}
for k, v in pairs(actions) do
	result[v.id] = {}
	CurrentID = v.id
    result[v.id].type = v.type
    if TypeToSpellList[v.type] == nil then
        TypeToSpellList[v.type] = {}
    end
    if TypeToSpellListCount[v.type] == nil then
        TypeToSpellListCount[v.type] = 1
    end--性能优化策略
    TypeToSpellList[v.type][TypeToSpellListCount[v.type]] = v.id
	TypeToSpellListCount[v.type] = TypeToSpellListCount[v.type] + 1
	TypeToSpellList.AllSpells[k] = v.id
	result[v.id].name = v.name
	result[v.id].description = v.description
	result[v.id].sprite = v.sprite
	result[v.id].mana = v.mana
    result[v.id].max_uses = v.max_uses
    result[v.id].spawn_probability = v.spawn_probability
	result[v.id].spawn_level = v.spawn_level
	v.action() --执行
	result[v.id].reload_time = current_reload_time
	if result[v.id].c == nil then
		result[v.id].c = {}
	end
	for ckey, cv in pairs(c) do
		result[v.id].c[ckey] = cv
	end
	if result[v.id].shot == nil then
		result[v.id].shot = {}
	end
	for shotkey, shotv in pairs(shot_effects) do
		result[v.id].shot[shotkey] = shotv
	end
	c = {}
	shot_effects = {}
	reset_modifiers(c)
	ConfigGunShotEffects_Init(shot_effects)
	current_reload_time = 0
end

local file = io.open("mods/wand_editor/cache/ModEnable.lua", "w") --将模组启动情况写入文件
file:write("return {\n" .. SerializeTable(ModIdToEnable, "") .. "}")
file:close()

file = io.open("mods/wand_editor/cache/SpellsData.lua", "w") --法术缓存写入文件
file:write("return {\n" .. SerializeTable(result, "") .. "}")
file:close()

file = io.open("mods/wand_editor/cache/TypeToSpellList.lua", "w") --法术列表缓存写入文件
file:write("return {\n" .. SerializeTable(TypeToSpellList, "") .. "}")
file:close()

reflecting = nil--删除变量
current_reload_time = nil
Reflection_RegisterProjectile = nil
EntityAddTag(player, "player_unit") --恢复状态

return {result, TypeToSpellList}

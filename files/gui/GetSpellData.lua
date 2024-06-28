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
local mustReload = false
if ModSettingGet(ModID.."VerHash") == nil then--如果为空就尝试进行初始化
	local hashPath = Cpp.CurrentPath().."/_version_hash.txt"
    if Cpp.PathExists(hashPath) then
        ModSettingSet(ModID .. "VerHash", ReadFileAll(hashPath))
    end
else
	local hashPath = Cpp.CurrentPath().."/_version_hash.txt"
    if Cpp.PathExists(hashPath) then--如果发现有的话就读取
        local newHash = ReadFileAll(hashPath)
		if newHash ~= ModSettingGet(ModID.."VerHash") then--不一致就设置新的
            ModSettingSet(ModID .. "VerHash", ReadFileAll(hashPath))
			mustReload = true --并且要刷新
		end
    end
end

--判断是否有缓存文件
local cachePath = Cpp.CurrentPath() .. "/mods/wand_editor/cache/"
local HasCahce = Cpp.PathExists(cachePath.."SpellsData.lua") and Cpp.PathExists(cachePath.."ModEnable.lua") and Cpp.PathExists(cachePath.."TypeToSpellList.lua")

--检查是否需要更新缓存
local ModIdToEnable = GetModEnableList()
if HasCahce and (not mustReload) then
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
	if true then--可以直接读取缓存！
		--print("Cache Get")
		local result1 = dofile_once("mods/wand_editor/cache/SpellsData.lua")
		local result2 = dofile_once("mods/wand_editor/cache/TypeToSpellList.lua")
		return {result1,result2}
	end
end
--print("Init Spell Data")
--需要重新加载
local result = {}

local CurrentID = nil
local hasProj = {}
draw_actions = function(draw)           --设置抽取数，当被调用时
	result[CurrentID].draw_actions = draw
end

--监听的数据
current_reload_time = 0 --充能时间

c = {}
reset_modifiers(c)                      --初始化
shot_effects = {}
ConfigGunShotEffects_Init(shot_effects) --初始化
shot_effects.recoil_knockback = QuietNaN
local isAssign = true
local function ShotListener(key, value)
	if key == "recoil_knockback" then
		if IsNaN(value) then
            isAssign = false
			return 0
		else
			if isAssign then
                result[CurrentID].true_recoil = "=" .. tostring(value)
            else
				result[CurrentID].true_recoil = NumToWithSignStr(value)
			end
		end
	end
end

TableListener(shot_effects, ShotListener)


reflecting = true
Reflection_RegisterProjectile = function(filepath)
	if not isAssign then
		return
	end
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
                elseif v.name == "LifetimeComponent" then --待完成
                    local lifetimeLimit = tonumber(v.attr.lifetime)
					if result[CurrentID].lifetimeLimit == nil or (result[CurrentID].lifetimeLimit ~= nil and lifetimeLimit <= result[CurrentID].lifetimeLimit) then
						result[CurrentID].lifetimeLimit = tonumber(v.attr.lifetime)
						hasProj[filepath].lifetimeLimit = result[CurrentID].lifetimeLimit
						if v.attr["randomize_lifetime.min"] ~= nil then
							result[CurrentID].lifetimeLimitMin = tonumber(v.attr["randomize_lifetime.min"])
							hasProj[filepath].lifetimeLimitMin = result[CurrentID].lifetimeLimitMin
						end
						if v.attr["randomize_lifetime.max"] ~= nil then
							result[CurrentID].lifetimeLimitMax = tonumber(v.attr["randomize_lifetime.max"])
							hasProj[filepath].lifetimeLimitMax = result[CurrentID].lifetimeLimitMax
						end
					end

                elseif v.name == "MagicXRayComponent" then--特殊情况
                    local radius = tonumber(v.attr.radius)
                    local steps_per_frame = tonumber(v.attr.steps_per_frame)
                    local lifetimeLimit = math.ceil(radius / steps_per_frame)
					if result[CurrentID].lifetimeLimit ~= nil then--判断是否有数据
                        if lifetimeLimit <= result[CurrentID].lifetimeLimit then--如果有的话就要判断谁小
                            result[CurrentID].lifetimeLimit = lifetimeLimit
                            hasProj[filepath].lifetimeLimit = result[CurrentID].lifetimeLimit
                            result[CurrentID].lifetimeLimitMin = nil
                            hasProj[filepath].lifetimeLimitMin = nil
                            result[CurrentID].lifetimeLimitMax = nil
                            hasProj[filepath].lifetimeLimitMax = nil
                        else
                            result[CurrentID].lifetimeLimit = lifetimeLimit
                            hasProj[filepath].lifetimeLimit = result[CurrentID].lifetimeLimit
                        end
                    else
						result[CurrentID].lifetimeLimit = lifetimeLimit
						hasProj[filepath].lifetimeLimit = result[CurrentID].lifetimeLimit
					end
				end
			end
			result[CurrentID].projComp = {}
			for k, v in pairs(ComponentGetMembers(projComp)) do --批量加载数据
				result[CurrentID].projComp[k] = v
			end
            hasProj[filepath].projComp = result[CurrentID].projComp
			
			ComponentSetValue2(projComp, "on_death_explode", false)
			ComponentSetValue2(projComp, "on_lifetime_out_explode", false)
			ComponentSetValue2(projComp, "collide_with_entities", false)
			ComponentSetValue2(projComp, "collide_with_world", false)

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
    if not isAssign then
        v.action()
    end
    for shotkey, shotv in pairs(shot_effects()) do
        result[v.id].shot[shotkey] = shotv
    end
    isAssign = true
	if c.extra_entities ~= "" then
        local extra_entities = split(c.extra_entities, ",")
		for _,ExtraEntityPath in pairs(extra_entities) do
            local ExtraEntity = ParseXmlAndBase(ExtraEntityPath)
			for _,EEv in pairs(ExtraEntity.children)do
                if EEv.name == "LifetimeComponent" then
                    result[v.id].lifetimeLimit = tonumber(EEv.attr.lifetime)
					if EEv.attr["randomize_lifetime.min"] ~= nil then
                        result[v.id].lifetimeLimitMin = tonumber(EEv.attr["randomize_lifetime.min"])
					end
                    if EEv.attr["randomize_lifetime.max"] ~= nil then
						result[v.id].lifetimeLimitMax = tonumber(EEv.attr["randomize_lifetime.max"])
					end
				end
			end
		end
	end
	c = {}
	shot_effects = {}
	reset_modifiers(c)
    ConfigGunShotEffects_Init(shot_effects)
    shot_effects.recoil_knockback = QuietNaN
	TableListener(shot_effects, ShotListener)

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

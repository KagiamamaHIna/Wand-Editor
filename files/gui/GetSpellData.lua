dofile_once("mods/wand_editor/files/libs/fn.lua")
dofile_once("data/scripts/gun/gun.lua")

---输入类型枚举量获得其对应的字符串
---@param type integer
---@return string
function SpellTypeEnumToStr(type)
	if type == ACTION_TYPE_PROJECTILE then
		return GameTextGetTranslatedOrNot("inventory_actiontype_projectile")
	elseif type == ACTION_TYPE_STATIC_PROJECTILE then
		return GameTextGetTranslatedOrNot("inventory_actiontype_staticprojectile")
	elseif type == ACTION_TYPE_MODIFIER then
		return GameTextGetTranslatedOrNot("inventory_actiontype_modifier")
	elseif type == ACTION_TYPE_DRAW_MANY then
		return GameTextGetTranslatedOrNot("inventory_actiontype_drawmany")
	elseif type == ACTION_TYPE_MATERIAL then
		return GameTextGetTranslatedOrNot("inventory_actiontype_material")
	elseif type == ACTION_TYPE_OTHER then
		return GameTextGetTranslatedOrNot("inventory_actiontype_other")
	elseif type == ACTION_TYPE_UTILITY then
		return GameTextGetTranslatedOrNot("inventory_actiontype_utility")
	elseif type == ACTION_TYPE_PASSIVE then
		return GameTextGetTranslatedOrNot("inventory_actiontype_passive")
	end
	return "unknown"
end

local result = {}

--监听的数据
current_reload_time = 0 --充能时间

c = {}
reset_modifiers(c)                      --初始化
shot_effects = {}
ConfigGunShotEffects_Init(shot_effects) --初始化

draw_actions = function(draw)           --设置抽取数，当被调用时
	result.draw_actions = draw
end

local CurrentID = nil
local hasProj = {}

reflecting = true
Reflection_RegisterProjectile = function(filepath)
    --获取投射物数据，判断是否有缓存
	if hasProj[filepath] == nil then
		local proj = EntityLoad("mods/wand_editor/files/entity/NullEntity.xml", 14600, -45804)
		EntityLoadToEntity(filepath, proj)
		hasProj[filepath] = {}
		local projComp = EntityGetFirstComponent(proj, "ProjectileComponent")
		if projComp then
            result[CurrentID].lifetime = ComponentGetValue2(projComp, "mStartingLifetime")
            hasProj[filepath].lifetime = result[CurrentID].lifetime
			
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
			end
		end
		--杀死实体
        EntityKill(proj)
    else
		--读取缓存
		for k,v in pairs(hasProj[filepath]) do
			result[CurrentID][k] = v
		end
	end

end

local player = GetPlayer()
EntityRemoveTag(player, "player_unit")

for _, v in pairs(actions) do
    result[v.id] = {}
    CurrentID = v.id
    result[v.id].type = v.type
    result[v.id].name = GameTextGetTranslatedOrNot(v.name)
    result[v.id].description = GameTextGetTranslatedOrNot(v.description)
    result[v.id].sprite = v.sprite
    result[v.id].mana = v.mana
    result[v.id].max_uses = v.max_uses
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

reflecting = nil
current_reload_time = nil
Reflection_RegisterProjectile = nil
EntityAddTag(player, "player_unit") --恢复状态

return result

dofile_once("mods/wand_editor/files/libs/fn.lua")
dofile_once("data/scripts/gun/gun_enums.lua")
local GetPlayerXY = Compose(EntityGetTransform, GetPlayer)

local LastSearch = ""--上一次的搜索记录，用于确认是否改变了搜索内容
local LastList--上一次的列表，缓存的数据
local LastType        --上一次的类型，用于判断是否需要重新搜索
local LastFn          --上一次调用的匹配函数，用于判断设置是否更改
local LastRatioMinScore --上一次的匹配分数，用于判断设置是否更改
local LastIDSearchMode  --上一次的是否启用id搜索模式，用于判断设置是否更改

local IsFavorite = false
local FavoriteTable
local HasFavorite
if ModSettingGet("wand_editor_FavoriteTable") == nil then
    ModSettingSet("wand_editor_FavoriteTable", "return {}")
end
if ModSettingGet("wand_editor_HasFavorite") == nil then
	ModSettingSet("wand_editor_HasFavorite","return {}")
end
FavoriteTable = loadstring(ModSettingGet("wand_editor_FavoriteTable"))()
HasFavorite = loadstring(ModSettingGet("wand_editor_HasFavorite"))()

local UesSearchRatio = Cpp.AbsPartialPinyinRatio
if ModSettingGet("wand_editor_RatioMinScore") == nil then
	ModSettingSet("wand_editor_RatioMinScore", 60)
end
local RatioMinScore = ModSettingGet("wand_editor_RatioMinScore")
local IDSearchMode = false

function SearchSpell(this, spellData, TypeToSpellList, SpellDrawType)
    local SearchSettingFn = function(_, _, posX, posY, SettingEnable)
        if SettingEnable then
            this.ScrollContainer("SearchSettingSrcoll", posX - 20, posY + 20, 180, 30, nil, 0)--绘制一个框
            this.AddAnywhereItem("SearchSettingSrcoll", function()
                this.checkbox("SearchMode", 0, 2, GameTextGetTranslatedOrNot("$wand_editor_search_fuzzy_setting"), nil,--一个checkbox，用于设置方面的选项
                    nil, function()
                    this.tooltips(function()
                        GuiText(this.gui, 0, 0, GameTextGetTranslatedOrNot("$wand_editor_search_fuzzy_setting_info"))
                    end,this.GetZDeep()-114514)
                end)
            end)
            this.AddAnywhereItem("SearchSettingSrcoll", function()
                this.checkbox("IdMode", 85, 2, GameTextGetTranslatedOrNot("$wand_editor_search_id_setting"), nil,--一个checkbox，用于设置方面的选项
                    nil, function()
                    this.tooltips(function()
                        GuiText(this.gui, 0, 0, GameTextGetTranslatedOrNot("$wand_editor_search_id_setting_info"))
                    end,this.GetZDeep()-114514)
                end)
            end)
            this.AddAnywhereItem("SearchSettingSrcoll", function()
				GuiZSetForNextWidget(this.gui, this.GetZDeep()-3)--不要再覆盖啦！
                ModSettingSet("wand_editor_RatioMinScore",--参数二即为要设置的值
                    GuiSlider(this.gui, this.NewID("FuzzySlider"), 0, 15,
                        GameTextGetTranslatedOrNot("$wand_editor_search_fuzzy_score_min_info"),
                        ModSettingGet("wand_editor_RatioMinScore"), 0, 99, 60, 1, "", 80))
				GuiTooltip(this.gui,GameTextGetTranslatedOrNot("$menuoptions_reset_keyboard"),"")
            end)

            this.DrawScrollContainer("SearchSettingSrcoll")
        end
    end
    if this.GetCheckboxEnable("SearchMode") then --如果处于启用状态那么设置搜索函数
        UesSearchRatio = Cpp.PinyinRatio
        RatioMinScore = ModSettingGet("wand_editor_RatioMinScore")
    else --因为另一种搜索规则如果大于0那么就是绝对相关的，因此就RatioMinScore设为0就行
        UesSearchRatio = Cpp.AbsPartialPinyinRatio
        RatioMinScore = 0
    end
	if this.GetCheckboxEnable("IdMode") then--如果处于启用状态那么设置ID搜索模式
		IDSearchMode = true
    else
		IDSearchMode = false
	end
	this.MoveImagePicker("SearchSetting", 50, 249, 5, 0, GameTextGetTranslatedOrNot("$wand_editor_search_setting"), "mods/wand_editor/files/gui/images/button_fold_open.png", nil, SearchSettingFn, "mods/wand_editor/files/gui/images/button_fold_close.png", nil, nil, true)

	GuiZSetForNextWidget(this.gui, this.GetZDeep()+1000)--不要再覆盖啦！
    local Search = this.TextInput("input", 63, 249, 123, 26)
	local _,_, hover = GuiGetPreviousWidgetInfo(this.gui)
    if hover and InputIsMouseButtonDown(Mouse_right) then
        this.TextInputRestore("input")
    end
	this.tooltips(function ()
		GuiText(this.gui,0,0,GameTextGetTranslatedOrNot("$wand_editor_search_info"))
    end, nil, 8, 16)
	local DrawSpellList
	if SpellDrawType ~= "favorite" then
        DrawSpellList = TypeToSpellList[SpellDrawType]
		IsFavorite = false
    else--特判
        DrawSpellList = FavoriteTable
		IsFavorite = true
	end
	--当搜索内容不为空且上一次搜索内容不等于现在的输入内容，或类型变化时搜索，或匹配分数变化时搜索，或搜索方式函数变化时搜索，或id搜索模式变化时搜索
    if (Search ~= "" and LastSearch ~= Search) or LastType ~= SpellDrawType or LastFn ~= UesSearchRatio or LastRatioMinScore ~= RatioMinScore or LastIDSearchMode ~= IDSearchMode then
		LastSearch = Search
        LastType = SpellDrawType
		SpellDrawType = "HasSearch"
        local ScoreToSpellID = {}
		local ScoreToSpellIDCount = {}--带有Count的(计数器)的变量代码均为性能优化，用于取代table.insert
        local ScoreList = {}
		local ScoreListCount = 1
        local HasScore = {}
        for _, v in pairs(DrawSpellList) do --循环计算匹配程度
            if spellData[v] == nil then
                goto continue
            end
            local searchText
            if IDSearchMode then
                searchText = v
            else
                searchText = GameTextGetTranslatedOrNot(spellData[v].name)
            end

            local score = UesSearchRatio(string.lower(searchText), string.lower(Search)) --大小写不敏感
            if ScoreToSpellID[score] == nil then
                ScoreToSpellID[score] = {}
                ScoreToSpellIDCount[score] = 1
            end
            ScoreToSpellID[score][ScoreToSpellIDCount[score]] = v
            ScoreToSpellIDCount[score] = ScoreToSpellIDCount[score] + 1
            if HasScore[score] == nil then
                ScoreList[ScoreListCount] = score
                ScoreListCount = ScoreListCount + 1
                HasScore[score] = true
            end
            ::continue::
        end
		--接下来进行排序
        table.sort(ScoreList)
        DrawSpellList = {}
		local DrawSpellListCount = 1
        for i = #ScoreList, 1, -1 do
            if ScoreList[i] > RatioMinScore then
                for _, v in pairs(ScoreToSpellID[ScoreList[i]]) do
					DrawSpellList[DrawSpellListCount] = v
					DrawSpellListCount = DrawSpellListCount + 1
                end
            else--如果有不符合条件的，这意味着之后的也都不符合，所以直接退出循环
                break
            end
        end
        LastList = DrawSpellList
        LastFn = UesSearchRatio
        LastRatioMinScore = RatioMinScore
		LastIDSearchMode = IDSearchMode
    elseif LastSearch == Search and LastType == SpellDrawType and Search ~= "" then
        DrawSpellList = LastList
    end
	return DrawSpellList,SpellDrawType
end

local SkipDrawMoreText = {
    ["RANDOM_SPELL"] = true,
    ["RANDOM_PROJECTILE"] = true,
    ["RANDOM_STATIC_PROJECTILE"] = true,
    ["RANDOM_MODIFIER"] = true,
    ["RANDOM_EXPLOSION"] = true,
	["DAMAGE_RANDOM"] = true,
}

---用于绘制法术文本
---@param this table
---@param id string
---@param idata table
local function DarwSpellText(this, id, idata)
	local rightMargin = 70
	local function NewLine(str1, str2)
		local text = GameTextGetTranslatedOrNot(str1)
		local w = GuiGetTextDimensions(this.gui,text)
		GuiLayoutBeginHorizontal(this.gui, 0, 0, true, 2, -1)
        GuiText(this.gui, 0, 0, text)
		GuiRGBAColorSetForNextWidget(this.gui, 210, 180, 140, 255)
		GuiText(this.gui, rightMargin - w, 0, str2)
		GuiLayoutEnd(this.gui)
	end

	GuiText(this.gui, 0, 0, GameTextGetTranslatedOrNot(idata.name))
	GuiColorSetForNextWidget(this.gui, 0.5, 0.5, 0.5, 1.0)
	GuiText(this.gui, 0, 0, id)
	GuiText(this.gui, 0, 0, GameTextGetTranslatedOrNot(idata.description))
	GuiColorSetForNextWidget(this.gui, 0.5, 0.5, 1.0, 1.0)
	GuiText(this.gui, 0, 0, SpellTypeEnumToStr(idata.type))
	
	GuiLayoutBeginVertical(this.gui, 0, 7, true) --垂直布局
    if idata.max_uses and idata.max_uses ~= -1 then
        NewLine("$wand_editor_max_uses", tostring(idata.max_uses)) --使用次数
    end
	
	NewLine("$inventory_manadrain", tostring(idata.mana))--耗蓝

    if SkipDrawMoreText[id] then
        GuiLayoutEnd(this.gui)
		return
    end
	
	if idata.draw_actions and idata.draw_actions ~= 0 then
		NewLine("$wand_editor_draw_many", tostring(idata.draw_actions))
	end

	if idata.projComp and idata.projComp.damage ~= "0" then --如果有投射物伤害
		NewLine("$inventory_damage", tostring(tonumber(idata.projComp.damage) * 25))
	end
	
	if idata.projComp and idata.projComp.on_death_explode ~= "0" then
		if idata.projExplosion and idata.projExplosion ~= 0 then --如果有爆炸伤害
			NewLine("$inventory_dmg_explosion", tostring(math.floor(idata.projExplosion * 25)))
		end
		if idata.projExplosionRadius and idata.projExplosionRadius ~= 0 then --如果有爆炸半径
			NewLine("$inventory_explosion_radius", tostring(idata.projExplosionRadius))
		end
	end
	
	if idata.true_recoil then --如果有后坐力
		NewLine("$wand_editor_recoil_knockback", idata.true_recoil)
	end

    if idata.projComp then
        for k, v in pairs(idata.projDmg) do --伤害参数
            if v ~= 0 then
                if k == "electricity" then
                    NewLine("$inventory_mod_damage_electric", tostring(v * 25))
                else
                    NewLine("$inventory_dmg_" .. k, tostring(v * 25))
                end
            end
        end
        --散射(实在是看不出来哪里来的，先放着)

        --速度
        local speed_min = tonumber(idata.projComp.speed_min)
        local speed_max = tonumber(idata.projComp.speed_max)
        if (speed_min == speed_max) and speed_min ~= 0 and speed_max ~= 0 then
            NewLine("$inventory_speed", tostring(speed_max))
        elseif speed_min ~= 0 and speed_max ~= 0 then
            NewLine("$inventory_speed",
                tostring(speed_min) .. GameTextGetTranslatedOrNot("$wand_editor_to") .. tostring(speed_max))
        end
        if idata.lifetime then
            local randomness = tonumber(idata.projComp.lifetime_randomness)
            if randomness ~= 0 then
                NewLine("$wand_editor_lifetime",
                    tostring(idata.lifetime - randomness) ..
                    "f" .. GameTextGetTranslatedOrNot("$wand_editor_to") .. tostring(idata.lifetime + randomness) .. "f")
            else
                NewLine("$wand_editor_lifetime", idata.lifetime .. "f")
            end
        end
    end
	
	if idata.lifetimeLimit then
		if idata.lifetimeLimitMin and idata.lifetimeLimitMax then
			NewLine("$wand_editor_lifetime_limit",
				tostring(idata.lifetimeLimit + idata.lifetimeLimitMin) ..
				"f" .. GameTextGetTranslatedOrNot("$wand_editor_to") .. tostring(idata.lifetimeLimit + idata.lifetimeLimitMax) .. "f")
		else
			NewLine("$wand_editor_lifetime_limit", tostring(idata.lifetimeLimit) .. "f")
		end
	end
	
	local SecondWithSign = Compose(NumToWithSignStr, tonumber, FrToSecondStr)
	if idata.c.fire_rate_wait ~= 0 then--施放延迟
		NewLine("$inventory_castdelay", SecondWithSign(idata.c.fire_rate_wait)  .. "s("..idata.c.fire_rate_wait.."f)" )
	end
	if idata.reload_time ~= 0 then --充能延迟
		NewLine("$inventory_rechargetime", SecondWithSign(idata.reload_time) .. "s("..idata.reload_time.."f)" )
	end
	
	if idata.c.lifetime_add ~= 0 then	--存在时间修正
		NewLine("$wand_editor_lifetime", NumToWithSignStr(idata.c.lifetime_add) .. "f" )
	end

	if idata.c.damage_critical_chance ~= 0 then --暴击几率
		NewLine("$inventory_mod_critchance", NumToWithSignStr(idata.c.damage_critical_chance) .. "%" )
	end

	if idata.c.spread_degrees ~= 0 then--散射修正
		NewLine("$inventory_spread", NumToWithSignStr(idata.c.spread_degrees) .. GameTextGetTranslatedOrNot("$wand_editor_deg") )
	end

	if idata.c.speed_multiplier ~= 1 then--投射物速度修正
		NewLine("$inventory_mod_speed", "x "..tostring(idata.c.speed_multiplier))
	end

	if idata.c.bounces ~= 0 then --弹跳次数
		NewLine("$inventory_mod_bounces", NumToWithSignStr(idata.c.bounces))
	end

	if idata.c.damage_projectile_add ~= 0 then--投射物伤害修正
		NewLine("$inventory_mod_damage", NumToWithSignStr(idata.c.damage_projectile_add * 25))
	end

	if idata.c.damage_healing_add ~= 0 then--治疗伤害修正
		NewLine("$inventory_mod_damage_healing", NumToWithSignStr(idata.c.damage_healing_add * 25))
	end

	if idata.c.damage_curse_add ~= 0 then--诅咒伤害修正
		NewLine("$inventory_mod_damage_curse", NumToWithSignStr(idata.c.damage_curse_add * 25))
	end

	if idata.c.damage_explosion_add ~= 0 then--爆炸伤害修正
		NewLine("$inventory_mod_damage_explosion", NumToWithSignStr(idata.c.damage_explosion_add * 25))
	end

	if idata.c.damage_slice_add ~= 0 then--切割伤害修正
		NewLine("$inventory_mod_damage_slice", NumToWithSignStr(idata.c.damage_slice_add * 25))
	end

	if idata.c.damage_ice_add ~= 0 then--冰冻伤害修正
		NewLine("$inventory_mod_damage_ice", NumToWithSignStr(idata.c.damage_ice_add * 25))
	end

	if idata.c.damage_melee_add ~= 0 then--近战伤害修正
		NewLine("$inventory_mod_damage_melee", NumToWithSignStr(idata.c.damage_melee_add * 25))
	end

	if idata.c.damage_drill_add ~= 0 then--穿凿伤害修正
		NewLine("$inventory_mod_damage_drill", NumToWithSignStr(idata.c.damage_drill_add * 25))
	end

	if idata.c.damage_fire_add ~= 0 then--火焰伤害修正
		NewLine("$inventory_mod_damage_fire", NumToWithSignStr(idata.c.damage_fire_add * 25))
	end

	if idata.c.damage_electricity_add ~= 0 then--雷电伤害修正
		NewLine("$inventory_mod_damage_electric", NumToWithSignStr(idata.c.damage_electricity_add * 25))
	end

	GuiLayoutEnd(this.gui)
end

---用于绘制法术容器
---@param this table
---@param spellData table 法术数据
---@param spellTable table 法术列表
---@param type integer|string
function DrawSpellContainer(this, spellData, spellTable, type)
    local ZDeepest = this.GetZDeep()
	local ContainerName = "SpellsScroll"..tostring(type)
	this.ScrollContainer(ContainerName, 30, 64, 178, 180, nil, 0, 1.3)
    for pos, id in pairs(spellTable) do
		if spellData[id] == nil then
			goto continue
		end
		this.SetZDeep(this.GetZDeep() + 3)--设置深度，确保行为正确
		local sprite = spellData[id].sprite

        local SpellHover = function() --绘制法术悬浮窗用函数
            if not this.UserData["HasSpellMove"] then --法术悬浮窗绘制
                this.tooltips(function()
                    DarwSpellText(this, id, spellData[id])
                end, this.GetZDeep() - 114514, 9, -10)
            end
        end
		
		local SpellCilck = function(left_click, right_click, x, y) --法术点击效果
            local shift = InputIsKeyDown(Key_LSHIFT) or InputIsKeyDown(Key_RSHIFT)
			local CTRL = InputIsKeyDown(Key_LCTRL) or InputIsKeyDown(Key_RCTRL)
			if left_click and shift then --shift+左键
				local inventory_full = EntityGetChildWithName(GetPlayer(), "inventory_full")
                if inventory_full then
                    local px, py = GetPlayerXY()
                    local spell = CreateItemActionEntity(id, px, py)
                    EntitySetComponentsWithTagEnabled(spell, "enabled_in_world", false)
                    EntityAddChild(inventory_full, spell)
                    GamePrint(GameTextGetTranslatedOrNot(spellData[id].name),
                        GameTextGetTranslatedOrNot("$wand_editor_added_spell"))
                end
            elseif left_click and CTRL then--ctrl+左键收藏/删除法术
				if IsFavorite then
                    HasFavorite[id] = nil
                    table.remove(FavoriteTable, pos)
					GamePrint(GameTextGetTranslatedOrNot(spellData[id].name),
						GameTextGetTranslatedOrNot("$wand_editor_remove_favorite"))
					ModSettingSet("wand_editor_FavoriteTable", "return {" .. SerializeTable(FavoriteTable) .. "}")
					ModSettingSet("wand_editor_HasFavorite", "return {" .. SerializeTable(HasFavorite) .. "}")
                else
					if HasFavorite[id] == nil then
                        table.insert(FavoriteTable, 1, id)
						HasFavorite[id] = true
						GamePrint(GameTextGetTranslatedOrNot(spellData[id].name),
							GameTextGetTranslatedOrNot("$wand_editor_added_favorite_spell"))
                        ModSettingSet("wand_editor_FavoriteTable", "return {" .. SerializeTable(FavoriteTable) .. "}")
						ModSettingSet("wand_editor_HasFavorite", "return {" .. SerializeTable(HasFavorite) .. "}")
                    else
						GamePrint(GameTextGetTranslatedOrNot(spellData[id].name),
							GameTextGetTranslatedOrNot("$wand_editor_added_favorite_Already"))
					end
				end
            elseif left_click and not this.GetNoMoveBool() then --纯左键
				this.UserData["SpellHoverEnable"] = false
				DrawFloatSpell(x,y,sprite,id)
			end
		end

		this.AddScrollImageItem(ContainerName, sprite, function()--添加图片项目的回调绘制
            GuiZSetForNextWidget(this.gui, this.GetZDeep())
			GuiOptionsAddForNextWidget(this.gui, GUI_OPTION.DrawWobble)--让法术摇摆
			this.MoveImageButton("__SPELL_" .. id, 0, 2, sprite, nil, SpellHover, SpellCilck, nil, true)--最后两个参数是不始终调用点击回调和禁止移动
			--绘制法术背景，深度要控制好
			GuiZSetForNextWidget(this.gui, this.GetZDeep() + 2)
			GuiImage(this.gui, this.NewID("__SPELL_" .. id .. "_BG"), -20, 0, "data/ui_gfx/inventory/full_inventory_box.png", 1, 1)
			GuiZSetForNextWidget(this.gui, this.GetZDeep() + 1)
			GuiImage(this.gui, this.NewID("__SPELL_" .. id .. "_SPELLBG"), -22, 0, SpellTypeBG[spellData[id].type], 1, 1)
        end)
		::continue::
	end
    GuiZSetForNextWidget(this.gui, this.GetZDeep() + 1) --设置深度，确保行为正确
	this.DrawScrollContainer(ContainerName)
end
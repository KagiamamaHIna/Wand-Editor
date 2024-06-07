dofile_once("mods/wand_editor/files/libs/fn.lua")
dofile_once("data/scripts/gun/gun_enums.lua")
local GetPlayerXY = Compose(EntityGetTransform, GetPlayer)
local hasMove = false --控制法术的Hover是否启用

local LastSearch = ""--上一次的搜索记录，用于确认是否改变了搜索内容
local LastList--上一次的列表，缓存的数据
local LastType        --上一次的类型，用于判断是否需要重新搜索
local LastFn          --上一次调用的匹配函数，用于判断设置是否更改
local LastRatioMinScore --上一次的匹配分数，用于判断设置是否更改

local UesSearchRatio = Cpp.AbsPartialPinyinRatio
if ModSettingGet("wand_editor_RatioMinScore") == nil then
	ModSettingSet("wand_editor_RatioMinScore", 60)
end
local RatioMinScore = ModSettingGet("wand_editor_RatioMinScore")

function SearchSpell(this, spellData, TypeToSpellList, SpellDrawType)
    local SearchSettingFn = function(_, _, posX, posY, SettingEnable)
        if SettingEnable then
            this.ScrollContainer("SearchSettingSrcoll", posX - 20, posY + 16, 180, 30, nil, 0)--绘制一个框
            this.AddAnywhereItem("SearchSettingSrcoll", function()
                this.checkbox("SearchMode", 0, 2, GameTextGetTranslatedOrNot("$wand_editor_search_fuzzy_setting"), nil,--一个checkbox，用于设置方面的选项
                    nil, function()
                    this.tooltips(function()
                        GuiText(this.gui, 0, 0, GameTextGetTranslatedOrNot("$wand_editor_search_fuzzy_setting_info"))
                    end)
                end)
            end)
            this.AddAnywhereItem("SearchSettingSrcoll", function()
                ModSettingSet("wand_editor_RatioMinScore",
                    GuiSlider(this.gui, this.NewID("FuzzySlider"), 0, 15,
                        GameTextGetTranslatedOrNot("$wand_editor_search_fuzzy_score_min_info"),
                        ModSettingGet("wand_editor_RatioMinScore"), 0, 99, 60, 1, "", 80))
            end)
            this.DrawScrollContainer("SearchSettingSrcoll")
        end
    end
	if this.GetCheckboxEnable("SearchMode") then--设置搜索函数
        UesSearchRatio = Cpp.PinyinRatio
		RatioMinScore = ModSettingGet("wand_editor_RatioMinScore")
    else
        UesSearchRatio = Cpp.AbsPartialPinyinRatio
		RatioMinScore = 0
	end
	this.MoveImagePicker("SearchSetting", 50, 245, 5, 0, GameTextGetTranslatedOrNot("$wand_editor_search_setting"), "mods/wand_editor/files/gui/images/button_fold_open.png", nil, SearchSettingFn, "mods/wand_editor/files/gui/images/button_fold_close.png", nil, true)

	GuiZSetForNextWidget(this.gui, this.GetZDeep()+114514)--不要再覆盖啦！
    local Search = this.TextInput("input", 63, 245, 123, 26)
	local _,_, hover = GuiGetPreviousWidgetInfo(this.gui)
    if hover and InputIsMouseButtonDown(Mouse_right) then
		this.TextInputRestore("input")
	end
	this.tooltips(function ()
		GuiText(this.gui,0,0,GameTextGetTranslatedOrNot("$wand_editor_search_info"))
    end, nil, 8, 16)
    local DrawSpellList = TypeToSpellList[SpellDrawType]
	--当搜索内容不为空且上一次搜索内容不等于现在的输入内容，或类型变化时搜索，或匹配分数变化时搜索，或搜索方式函数变化时搜索
    if (Search ~= "" and LastSearch ~= Search) or LastType ~= SpellDrawType or LastFn ~= UesSearchRatio or LastRatioMinScore ~= RatioMinScore then
        LastSearch = Search
		LastType = SpellDrawType
        local ScoreToSpellID = {}
        local ScoreList = {}
        local HasScore = {}
        for _, v in pairs(DrawSpellList) do
            local score = UesSearchRatio(string.lower(GameTextGetTranslatedOrNot(spellData[v].name)), string.lower(Search))--大小写不敏感
            if ScoreToSpellID[score] == nil then
                ScoreToSpellID[score] = {}
            end
            table.insert(ScoreToSpellID[score], v)
            if HasScore[score] == nil then
                table.insert(ScoreList, score)
                HasScore[score] = true
            end
        end
        table.sort(ScoreList)
        DrawSpellList = {}
        for i = #ScoreList, 1, -1 do
            if ScoreList[i] > RatioMinScore then --匹配度超过60就进入结果中
                for _, v in pairs(ScoreToSpellID[ScoreList[i]]) do
                    table.insert(DrawSpellList, v)
                end
            else
                break
            end
        end
        LastList = DrawSpellList
        LastFn = UesSearchRatio
		LastRatioMinScore = RatioMinScore
    elseif LastSearch == Search and LastType == SpellDrawType and Search ~= "" then
        DrawSpellList = LastList
    end
	return DrawSpellList
end

---用于绘制法杖文本
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
	
	local function NumToWithSignStr(num)
		local result
		if num >= 0 then
			result = "+" .. tostring(num)
		else
			result = tostring(num)
		end
		return result
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

	if idata.draw_actions and idata.draw_actions ~= 0 then
		NewLine("$wand_editor_draw_many", tostring(idata.draw_actions))
	end

	if idata.projComp and idata.projComp.damage ~= "0" then --如果有投射物伤害
		NewLine("$inventory_damage", tostring(tonumber(idata.projComp.damage) * 25))
	end
	
	if idata.projExplosion and idata.projExplosion ~= 0 then --如果有爆炸伤害
		NewLine("$inventory_dmg_explosion", tostring(math.floor(idata.projExplosion * 25)))
	end
    if idata.projExplosionRadius and idata.projExplosionRadius ~= 0 then --如果有爆炸半径
        NewLine("$inventory_explosion_radius", tostring(idata.projExplosionRadius))
    end
	
	if idata.shot.recoil_knockback ~= 0 then
		NewLine("$wand_editor_recoil_knockback", tostring(idata.shot.recoil_knockback))
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
			NewLine("$inventory_speed", tostring(speed_min) .. GameTextGetTranslatedOrNot("$wand_editor_to") .. tostring(speed_max))
		end
		if idata.lifetime then
			local randomness = tonumber(idata.projComp.lifetime_randomness)
			if randomness ~= 0 then
				NewLine("$wand_editor_lifetime", tostring(idata.lifetime - randomness) .. "f".. GameTextGetTranslatedOrNot("$wand_editor_to") .. tostring(idata.lifetime + randomness).."f")
			else
				NewLine("$wand_editor_lifetime", idata.lifetime.."f")
			end
		end
	end
	local SecondWithSign = Compose(NumToWithSignStr, tonumber, FrToSecondStr)
	if idata.c.fire_rate_wait ~= 0 then--施放延迟
		NewLine("$inventory_castdelay", SecondWithSign(idata.c.fire_rate_wait)  .. "s("..idata.c.fire_rate_wait.."f)" )
	end
	if idata.reload_time ~= 0 then --充能延迟
		NewLine("$inventory_rechargetime", SecondWithSign(idata.reload_time) .. "s("..idata.reload_time.."f)" )
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

local TypeBG = {
	[ACTION_TYPE_PROJECTILE] = "data/ui_gfx/inventory/item_bg_projectile.png",
	[ACTION_TYPE_STATIC_PROJECTILE] = "data/ui_gfx/inventory/item_bg_static_projectile.png",
	[ACTION_TYPE_MODIFIER] = "data/ui_gfx/inventory/item_bg_modifier.png",
	[ACTION_TYPE_DRAW_MANY] = "data/ui_gfx/inventory/item_bg_draw_many.png",
	[ACTION_TYPE_MATERIAL] = "data/ui_gfx/inventory/item_bg_material.png",
	[ACTION_TYPE_OTHER] = "data/ui_gfx/inventory/item_bg_other.png",
	[ACTION_TYPE_UTILITY] = "data/ui_gfx/inventory/item_bg_utility.png",
	[ACTION_TYPE_PASSIVE] = "data/ui_gfx/inventory/item_bg_passive.png"
}

---用于绘制法术容器
---@param this table
---@param spellData table 法术数据
---@param spellTable table 法术列表
---@param type integer|string
function DrawSpellContainer(this, spellData, spellTable, type)
    local ZDeepest = this.GetZDeep()
	local ContainerName = "SpellsScroll"..tostring(type)
	this.ScrollContainer(ContainerName, 30, 60, 178, 180, nil, 0, 1.3)
	for _, id in pairs(spellTable) do
		this.SetZDeep(this.GetZDeep() + 3)--设置深度，确保行为正确
		local sprite = spellData[id].sprite

        local SpellHover = function() --绘制法术悬浮窗用函数
            if not hasMove then --法术悬浮窗绘制
                this.tooltips(function()
                    DarwSpellText(this, id, spellData[id])
                end, this.GetZDeep() - 12, 7)
            end
        end
		
		local SpellCilck = function(left_click, right_click, x, y) --法术点击效果
			local shift = InputIsKeyDown(Key_LSHIFT) or InputIsKeyDown(Key_RSHIFT)
			if left_click and shift then --shift+左键
				local inventory_full = EntityGetChildWithName(GetPlayer(), "inventory_full")
				if inventory_full then
					local px, py = GetPlayerXY()
					local spell = CreateItemActionEntity(id, px, py)
					EntitySetComponentsWithTagEnabled(spell, "enabled_in_world", false)
					EntityAddChild(inventory_full, spell)
					GamePrint(GameTextGetTranslatedOrNot(spellData[id].name),GameTextGetTranslatedOrNot("$wand_editor_added_spell"))
				end
			elseif left_click then --纯左键
				hasMove = true
				this.TickEventFn["MoveSpellFn"] = function() --分离出一个事件，用于表示法术点击后的效果
					local click = InputIsMouseButtonDown(Mouse_right)
					if click or GameIsInventoryOpen() then                          --右键取消，或打开物品栏取消
						this.OnMoveImage("MoveSpell", x, y, sprite, true)
						this.TickEventFn["MoveSpellFn"] = nil
						hasMove = false
						return
					end
                    --绘制悬浮图标
					local status = this.OnMoveImage("MoveSpell", x, y, sprite, nil, nil, ZDeepest-1,
						function(movex, movey)
							GuiZSetForNextWidget(this.gui, ZDeepest)
							GuiImage(this.gui, this.NewID("MoveSpell_BG"), movex - 2, movey - 2, TypeBG[spellData[id].type], 1, 1) --绘制背景
						end)
					if not status then
						this.TickEventFn["MoveSpellFn"] = nil
						local worldx, worldy = DEBUG_GetMouseWorld()
						CreateItemActionEntity(id, worldx, worldy+5)
						hasMove = false
					end
				end
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
			GuiImage(this.gui, this.NewID("__SPELL_" .. id .. "_SPELLBG"), -22, 0, TypeBG[spellData[id].type], 1, 1)
        end)
		
	end
	GuiZSetForNextWidget(this.gui, this.GetZDeep()+ 1)--设置深度，确保行为正确
	this.DrawScrollContainer(ContainerName)
end

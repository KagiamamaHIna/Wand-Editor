dofile_once("mods/wand_editor/files/libs/fn.lua")
dofile_once("data/scripts/gun/gun_enums.lua")
local GetPlayerXY = Compose(EntityGetTransform, GetPlayer)
local fastConcatStr = Cpp.ConcatStr

local LastSearch = ""--上一次的搜索记录，用于确认是否改变了搜索内容
local LastList--上一次的列表，缓存的数据
local LastType        --上一次的类型，用于判断是否需要重新搜索
local LastFn          --上一次调用的匹配函数，用于判断设置是否更改
local LastRatioMinScore --上一次的匹配分数，用于判断设置是否更改
local LastIDSearchMode  --上一次的是否启用id搜索模式，用于判断设置是否更改
local LastListMax

local IsFavorite = false
local FavoriteTable
local HasFavorite
if ModSettingGet("wand_editor_FavoriteTable") == nil then
    ModSettingSet("wand_editor_FavoriteTable", "return {}")
end
if ModSettingGet("wand_editor_HasFavorite") == nil then
    ModSettingSet("wand_editor_HasFavorite", "return {}")
end

---安全性检查，防止其他模组篡改
---@param str string
---@return table
local function SafeLoad(str)
    local luaStr = tostring(ModSettingGet(str))
	if HasEnds(luaStr) then
        ModSettingSet("wand_editor_FavoriteTable", "return {}")
        ModSettingSet("wand_editor_HasFavorite", "return {}")
        return {}
	end
    local CheckFn = loadstring(tostring(luaStr))
    if type(CheckFn) ~= "function" then
        ModSettingSet("wand_editor_FavoriteTable", "return {}")
        ModSettingSet("wand_editor_HasFavorite", "return {}")
        return {}
    end
	local fn = setfenv(CheckFn, {})
	local flag, result = pcall(fn)
	if not flag then--数据恢复为空表，有代码或其他行为试图篡改为非法数据
        ModSettingSet("wand_editor_FavoriteTable", "return {}")
        ModSettingSet("wand_editor_HasFavorite", "return {}")
		return {}
	end
	return result
end

FavoriteTable = SafeLoad("wand_editor_FavoriteTable")
HasFavorite = SafeLoad("wand_editor_HasFavorite")

local UesSearchRatio = Cpp.AbsPartialPinyinRatio
if ModSettingGet("wand_editor_RatioMinScore") == nil then
	ModSettingSet("wand_editor_RatioMinScore", 60)
end
local RatioMinScore = ModSettingGet("wand_editor_RatioMinScore")
local IDSearchMode = false
local SearchHistoryList = {}
local SearchKey

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

            this.DrawScrollContainer("SearchSettingSrcoll", false)
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
    local Search = this.TextInput("input", 63, 249, 123, -1)
	local _,_, hover = GuiGetPreviousWidgetInfo(this.gui)
    if hover and InputIsMouseButtonJustDown(Mouse_right) then
        this.TextInputRestore("input")
        GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", GameGetCameraPos())
    end
    if hover then
        UI.UserData["SavedSearchHistory"] = false
		if SearchKey == nil and Search ~= "" and InputIsKeyJustDown(Key_DOWN) then
			if Search ~= SearchHistoryList[#SearchHistoryList] then--需要判断是否是刚才保存过的，避免重复
				PushValueOnList(SearchHistoryList, Search)
				if #SearchHistoryList > 20 then --移除过多内容
					table.remove(SearchHistoryList, 1)
				end
			end
			this.SetInputText("input", "")
		elseif #SearchHistoryList > 0 then--当列表有可选内容时会进行的操作
            if InputIsKeyJustDown(Key_UP) then
                if Search ~= "" and SearchKey == nil then
					if Search ~= SearchHistoryList[#SearchHistoryList] then--需要判断是否是刚才保存过的，避免重复
						PushValueOnList(SearchHistoryList, Search)
						if #SearchHistoryList > 20 then --移除过多内容
							table.remove(SearchHistoryList, 1)
						end
					end
                    SearchKey = math.max(1, #SearchHistoryList - 1)
                elseif SearchKey == nil then
                    SearchKey = #SearchHistoryList
                else
                    SearchKey = math.max(1, SearchKey - 1)
                end
                this.SetInputText("input", SearchHistoryList[SearchKey])
            elseif InputIsKeyJustDown(Key_DOWN) and SearchKey then
                SearchKey = SearchKey + 1
                if SearchKey <= #SearchHistoryList then
                    this.SetInputText("input", SearchHistoryList[SearchKey])
                else
                    SearchKey = nil
                    this.SetInputText("input", "")
                end
            end
		end
    end
    if not hover and not UI.UserData["SavedSearchHistory"] then --历史搜索数据存储
        if (#SearchHistoryList > 0 and SearchHistoryList[#SearchHistoryList] ~= Search) or #SearchHistoryList == 0 then
            if Search ~= "" and SearchKey == nil then
                PushValueOnList(SearchHistoryList, Search)
                if #SearchHistoryList > 20 then --移除过多内容
                    table.remove(SearchHistoryList, 1)
                end
            end
            if SearchHistoryList[SearchKey] ~= Search then --文本不相同时再清除搜索key用于记录新的搜索文本
                SearchKey = nil
            end
        end
        UI.UserData["SavedSearchHistory"] = true
    end
	--TablePrint(SearchHistoryList)
	
	this.tooltips(function ()
		GuiText(this.gui,0,0,GameTextGetTranslatedOrNot("$wand_editor_search_info"))
    end, nil, 8, 16)
	local DrawSpellList
    if SpellDrawType ~= "favorite" then
        DrawSpellList = TypeToSpellList[SpellDrawType]
        IsFavorite = false
    else --特判
        DrawSpellList = FavoriteTable
        IsFavorite = true
    end
	local SearchList
	if ModSettingGet(ModID .. ".split_search_text") then
		SearchList = split(string.lower(Search), " ")
	else
		SearchList = { string.lower(Search) }
	end
	--当搜索内容不为空且上一次搜索内容不等于现在的输入内容，或类型变化时搜索，或匹配分数变化时搜索，或搜索方式函数变化时搜索，或id搜索模式变化时搜索
    if (Search ~= "" and LastSearch ~= Search) or LastType ~= SpellDrawType or LastFn ~= UesSearchRatio or LastRatioMinScore ~= RatioMinScore or LastIDSearchMode ~= IDSearchMode or #SearchList ~= LastListMax then
		if Search == "" then
			return DrawSpellList,SpellDrawType
		end
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
            local score = 0
			for _,lowerSearch in pairs(SearchList)do
                local TempScore = UesSearchRatio(string.lower(GameTextGetTranslatedOrNot(spellData[v].name)), lowerSearch) --大小写不敏感
                if TempScore > score then
                    score = TempScore
                end
                if string.byte(lowerSearch, 1, 1) == string.byte("@") then
					local ModIdSearch = string.sub(lowerSearch,2)
					local ModIdScore = UesSearchRatio(string.lower(GameTextGetTranslatedOrNot(spellData[v].wand_editor_from or "?")), ModIdSearch)
					if ModIdScore > score then
						score = ModIdScore
					end
				end
				local IDScore = 0
				if IDSearchMode then
					IDScore = UesSearchRatio(string.lower(v), lowerSearch)
				end
				local key = string.sub(spellData[v].name, 2)
				local EnStr = CSV.get(key, "en")
				local EnScore = 0
				if EnStr ~= nil then
					EnScore = UesSearchRatio(string.lower(EnStr), lowerSearch)
				end
				if IDScore > score then
					score = IDScore
				end
				if EnScore > score then
					score = EnScore
				end
			end
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
		LastListMax = #SearchList
    elseif LastSearch == Search and LastType == SpellDrawType and Search ~= "" then
        DrawSpellList = LastList
    end
	return DrawSpellList,SpellDrawType
end
local data = dofile_once("mods/wand_editor/files/gui/GetSpellData.lua") --读取法术数据
local spellData = data[1]

local TypeToSpellList = data[2]
local SpellDrawType = "AllSpells"
local TypeList = {
	"AllSpells",
	ACTION_TYPE_PROJECTILE,
	ACTION_TYPE_STATIC_PROJECTILE,
	ACTION_TYPE_MODIFIER,
	ACTION_TYPE_DRAW_MANY,
	ACTION_TYPE_MATERIAL,
	ACTION_TYPE_OTHER,
	ACTION_TYPE_UTILITY,
	ACTION_TYPE_PASSIVE,
	"favorite"
}
local SpellList = {
	AllSpells = "AllSpells",
	[ACTION_TYPE_PROJECTILE] = "projectile",
	[ACTION_TYPE_STATIC_PROJECTILE] = "static_projectile",
	[ACTION_TYPE_MODIFIER] = "modifier",
	[ACTION_TYPE_DRAW_MANY] = "draw_many",
	[ACTION_TYPE_MATERIAL] = "material",
	[ACTION_TYPE_OTHER] = "other",
	[ACTION_TYPE_UTILITY] = "utility",
	[ACTION_TYPE_PASSIVE] = "passive",
}

local GetPlayerWandID = Compose(GetEntityHeldWand, GetPlayer)

function SpellDepotClickCB(_, right_click, _, _, depot_enable)
	if right_click then
		local status = ModSettingGet(fastConcatStr(ModID,"SpellDepotCloseSpellOnGround"))
        if status == nil then
            ModSettingSet(fastConcatStr(ModID , "SpellDepotCloseSpellOnGround"), true)
        else
            ModSettingSet(fastConcatStr(ModID , "SpellDepotCloseSpellOnGround"), not status)
        end
		GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", GameGetCameraPos())
	end
	if not depot_enable then
		return
	end
	local function HelpHover()
		UI.tooltips(function()
			GuiText(UI.gui, 0, 0, GameTextGetTranslatedOrNot("$wand_editor_search_help"))
		end, UI.GetZDeep()-114514, 5)
	end
	UI.MoveImageButton("SpellDepotHelp", 200, 249,
		"mods/wand_editor/files/gui/images/help.png", nil, HelpHover, nil, nil, true)

	local function WandContainerClickCB(_, _, _, _, WandContainer_enable)
		if WandContainer_enable then
			DrawWandContainer(GetPlayerWandID(), spellData)
		end
	end
    local wandEditBoxText = GameTextGet("$wand_editor_wand_edit_box")
	local y_offest = 20
	if UI.GetPickerStatus("WandContainerBTN") then
        wandEditBoxText = wandEditBoxText .. GameTextGet("$wand_editor_wand_edit_box_help")
		y_offest = 0
	end
	UI.MoveImagePicker("WandContainerBTN", 28, 247, 8, y_offest,
		wandEditBoxText,"mods/wand_editor/files/gui/images/wand_container.png", nil, WandContainerClickCB,
		nil, true, true, true)

	local DrawSpellList, InputType = SearchSpell(UI, spellData, TypeToSpellList,
		SpellDrawType)
	--绘制容器
	DrawSpellContainer(UI, spellData, DrawSpellList, InputType)
	for i, v in pairs(TypeList) do     --绘制左边选择类型按钮
		local sprite
		if v == "AllSpells" then
			sprite = fastConcatStr(ModDir , "files/gui/images/all_spells.png")
		elseif v == "favorite" then
			sprite = fastConcatStr(ModDir , "files/gui/images/favorite_icon.png")
		else
			sprite = fastConcatStr(ModDir , "files/gui/images/" , SpellList[v] , "_icon.png")
		end

		local Hover = function()
			local _, _, hover = GuiGetPreviousWidgetInfo(UI.gui)
			if hover then
				SpellDrawType = v
				local HoverText
				if v == "AllSpells" then
					HoverText = GameTextGetTranslatedOrNot("$wand_editor_All_spells")
				elseif v == "favorite" then
					HoverText = GameTextGetTranslatedOrNot("$wand_editor_favorite")
				else
					HoverText = SpellTypeEnumToStr(v)
				end
				UI.tooltips(function()
					GuiText(UI.gui, 0, 0, HoverText)
				end, nil, nil, nil, true)
			end
		end
        if SpellDrawType ~= v then
            GuiOptionsAddForNextWidget(UI.gui, GUI_OPTION.DrawSemiTransparent)
        end
		GuiZSetForNextWidget(UI.gui, UI.GetZDeep())
		UI.MoveImageButton("Switch" .. v, 7, 44 + i * 20, sprite, nil, Hover, nil, nil, true)
	end
end

local SkipDrawMoreText = {
    ["RANDOM_SPELL"] = true,
    ["RANDOM_PROJECTILE"] = true,
    ["RANDOM_STATIC_PROJECTILE"] = true,
    ["RANDOM_MODIFIER"] = true,
    ["RANDOM_EXPLOSION"] = true,
	["DAMAGE_RANDOM"] = true,
}

local DrawLastText = function (LastText, cb)
	GuiLayoutAddVerticalSpacing(UI.gui, 5)
	local spaceX = GuiGetTextDimensions(UI.gui, LastText)
	GuiText(UI.gui, spaceX, 0, " ")
	local _, _, _, x, y = GuiGetPreviousWidgetInfo(UI.gui)
    GuiOptionsAddForNextWidget(UI.gui, GUI_OPTION.Layout_NoLayouting)
	if cb then
		cb()
	end
	GuiText(UI.gui, x - spaceX, y, LastText)
end

---用于绘制法术文本
---@param this table
---@param id string
---@param idata table
function HoverDarwSpellText(this, id, idata, Uses, LastText)
    local world_entity_id = GameGetWorldStateEntity()
    local comp_worldstate = EntityGetFirstComponent(world_entity_id, "WorldStateComponent")
    local inf_spells_enable = ComponentGetValue2(comp_worldstate, "perk_infinite_spells")
	
	local rightMargin = 72
	local function NewLine(str1, str2)
		local text = GameTextGetTranslatedOrNot(str1)
		local w = GuiGetTextDimensions(this.gui,text)
        GuiLayoutBeginHorizontal(this.gui, 0, 0, true, 2, -1)
        GuiText(this.gui, 0, 0, text)
        GuiRGBAColorSetForNextWidget(this.gui, 255, 222, 173, 255)
		if w + 8 > rightMargin then
			GuiText(this.gui, w + 8 - w, 0, str2)
        else
			GuiText(this.gui, rightMargin - w, 0, str2)
		end
		GuiLayoutEnd(this.gui)
	end
    local name = GameTextGetTranslatedOrNot(idata.name)
	if Uses and Uses ~= -1 then
		name = name.." ("..tostring(Uses)..")"
	end
	GuiText(this.gui, 0, 0, string.upper(name))
	GuiColorSetForNextWidget(this.gui, 0.5, 0.5, 0.5, 1.0)
	GuiText(this.gui, 0, 0, id)
	GuiText(this.gui, 0, 0, GameTextGetTranslatedOrNot(idata.description))
	GuiColorSetForNextWidget(this.gui, 0.5, 0.5, 1.0, 1.0)
	GuiText(this.gui, 0, 0, SpellTypeEnumToStr(idata.type))
	
	GuiLayoutAddVerticalSpacing(UI.gui,7)
	--GuiLayoutBeginVertical(this.gui, 0, 7, true) --垂直布局
    if idata.max_uses and idata.max_uses ~= -1 then
		if (inf_spells_enable and idata.never_unlimited) or not inf_spells_enable then
			NewLine("$wand_editor_max_uses", tostring(idata.max_uses)) --使用次数
		end
    end
	
	NewLine("$inventory_manadrain", tostring(idata.mana))--耗蓝

    if SkipDrawMoreText[id] then
		DrawLastText(idata.wand_editor_from or "?",function ()
			GuiRGBAColorSetForNextWidget(this.gui, 72, 209, 204, 255)
		end)
		if LastText then
			DrawLastText(LastText)
		end
		return
    end
	
	if idata.draw_actions and idata.draw_actions ~= 0 then
		NewLine("$wand_editor_draw_many", tostring(idata.draw_actions))
	end

	if idata.timerLifeTime then
		NewLine("$wand_editor_timer_life_time", tostring(idata.timerLifeTime).."f")
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
        --散射
        if idata.projComp.direction_random_rad ~= "0" then
            local rad = tonumber(idata.projComp.direction_random_rad)
			local formatted = string.format("%.2f",math.deg(rad)) .. GameTextGetTranslatedOrNot("$wand_editor_deg")
			NewLine("$inventory_spread", formatted)
		end
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

    if idata.c.damage_electricity_add ~= 0 then --雷电伤害修正
        NewLine("$inventory_mod_damage_electric", NumToWithSignStr(idata.c.damage_electricity_add * 25))
    end
	DrawLastText(idata.wand_editor_from or "?",function ()
		GuiRGBAColorSetForNextWidget(this.gui, 72, 209, 204, 255)
	end)
    if LastText then
		DrawLastText(LastText)
    end
end

local LastHistoryTable = {}
local HistoryTableMap = {}

local NewUseHistory = function (id)
	if HistoryTableMap[id] == nil then
		table.insert(LastHistoryTable, 1, id)
		HistoryTableMap[id] = true
	elseif HistoryTableMap[id] then
		local KeyPos
		for key, Value in pairs(LastHistoryTable) do
			if Value == id then
				KeyPos = key
				break
			end
		end
		table.remove(LastHistoryTable, KeyPos)
		table.insert(LastHistoryTable, 1, id)
	end
	if #LastHistoryTable > 18 then
		HistoryTableMap[LastHistoryTable[19]] = false
		table.remove(LastHistoryTable,19)
	end
	ModSettingSet(ModID .. "SpellDepotHistoryData", fastConcatStr("return {",SerializeTable(LastHistoryTable),"}"))
end
---用于绘制法术容器
---@param this table
---@param spellData table 法术数据
---@param spellTable table 法术列表
---@param type integer|string
function DrawSpellContainer(this, spellData, spellTable, type)
    local ZDeepest = this.GetZDeep()
    local ContainerName = fastConcatStr("SpellsScroll", tostring(type))
	if UI.GetPickerStatus("SpellDepotHistoryMode") then
        this.ScrollContainer(ContainerName, 30, 64, 178, 130, nil, 0, 1.35)
        this.ScrollContainer("HistorySpells", 30, 200, 178, 45, nil, 0, 1.35)

        local RemoveCB = function(left_click)
            if left_click then
                GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", GameGetCameraPos())
                if UI.UserData["RemoveSpellDepotHistoryBtn_IKnowWhatImDoing"] == nil then
                    UI.UserData["RemoveSpellDepotHistoryBtn_IKnowWhatImDoing"] = true
                    return
                end
                HistoryTableMap = {}
                LastHistoryTable = {}
                ModSettingSet(ModID .. "SpellDepotHistoryData", "return {}")
                UI.UserData["RemoveSpellDepotHistoryBtn_IKnowWhatImDoing"] = nil
            end
        end
		GuiZSetForNextWidget(UI.gui,UI.GetZDeep())
		UI.MoveImageButton("RemoveSpellDepotHistoryBtn", 215, 200,
            "mods/wand_editor/files/gui/images/remove_spell_depot_history.png", nil, function()
			local _,_,hover = GuiGetPreviousWidgetInfo(UI.gui)
			if UI.UserData["RemoveSpellDepotHistoryBtn_IKnowWhatImDoing"] then
				GuiTooltip(UI.gui, GameTextGet("$wand_editor_remove_spell_depot_history_IKnowWhatImDoing"), "")
            else
				GuiTooltip(UI.gui, GameTextGet("$wand_editor_remove_spell_depot_history"), "")
			end
			if not hover and UI.UserData["RemoveSpellDepotHistoryBtn_IKnowWhatImDoing"] then
				UI.UserData["RemoveSpellDepotHistoryBtn_IKnowWhatImDoing"] = nil
			end
		end, RemoveCB, false, true)
    else
		this.ScrollContainer(ContainerName, 30, 64, 178, 180, nil, 0, 1.3)
	end
	local SpellSlotDraw = function (pos,id,Container,GuiID)
		this.SetZDeep(this.GetZDeep() + 3)--设置深度，确保行为正确
		local sprite = spellData[id].sprite

        local SpellHover = function()                 --绘制法术悬浮窗用函数
            local _, _, hover = GuiGetPreviousWidgetInfo(UI.gui)
			this.UserData["WandContainerHasHover"] = this.UserData["WandContainerHasHover"] or hover
            if not this.UserData["HasSpellMove"] then --法术悬浮窗绘制
                UI.BetterTooltips(function()
					local world_entity_id = GameGetWorldStateEntity()
					local comp_worldstate = EntityGetFirstComponent(world_entity_id, "WorldStateComponent")
                    local inf_spells_enable = ComponentGetValue2(comp_worldstate, "perk_infinite_spells")
					
                    local max
					if (inf_spells_enable and spellData[id].never_unlimited) or not inf_spells_enable then
						max = spellData[id].max_uses
					end
                    HoverDarwSpellText(this, id, spellData[id],max)
                end, this.GetZDeep() - 114514,8,24)
            end
        end
		
		local SpellCilck = function(left_click, right_click, x, y) --法术点击效果
            local CTRL = InputIsKeyDown(Key_LCTRL) or InputIsKeyDown(Key_RCTRL)
            local ALT = InputIsKeyDown(Key_LALT) or InputIsKeyDown(Key_RALT)
            local SHIFT = InputIsKeyDown(Key_LSHIFT) or InputIsKeyDown(Key_RSHIFT)
            if left_click and SHIFT then                                                                                                                --快捷添加法术
                local CurrentWand
                if this.UserData["FixedWand"] and this.UserData["HasShiftClick"] and this.UserData["HasShiftClick"][this.UserData["FixedWand"][2]] then --固定的法杖必须是有选框才能判定
                    CurrentWand = this.UserData["FixedWand"][2]
                else                                                                                                                                    --否则就判断手持
                    local HeldWand = Compose(GetEntityHeldWand, GetPlayer)()
                    if HeldWand then
                        CurrentWand = HeldWand
                    end
                end
                if CurrentWand and this.UserData["HasShiftClick"] and this.UserData["HasShiftClick"][CurrentWand] then --如果是有选框的
                    local wandData = GetWandData(CurrentWand)
                    local HasShiftClick = this.UserData["HasShiftClick"][CurrentWand]
                    local min = HasShiftClick[2]
                    local max = HasShiftClick[3] or min
                    min = math.min(min, max)
                    max = math.max(HasShiftClick[2], max)
                    if min == max then --如果是单个选框的
                        SetTableSpells(wandData, id, min)
                        InitWand(wandData, CurrentWand)
                        HasShiftClick[2] = HasShiftClick[2] + 1
                    else --反之就是多个
                        for i = min, max do
                            SetTableSpells(wandData, id, i)
                        end
                        InitWand(wandData, CurrentWand)
                        this.UserData["HasShiftClick"][CurrentWand] = nil
                    end
                    this.OnceCallOnExecute(function()
                        RefreshHeldWands()
                    end)
					NewUseHistory(id)
                elseif CurrentWand then --没有选框
                    local wandData = GetWandData(CurrentWand)
                    for k, v in pairs(wandData.spells.spells) do
                        if v == "nil" then
                            SetTableSpells(wandData, id, k)
                            InitWand(wandData, CurrentWand)
                            break
                        end
                    end
                    this.OnceCallOnExecute(function()
                        RefreshHeldWands()
                    end)
					NewUseHistory(id)
                end
			elseif right_click and SHIFT then
                local CurrentWand
                if this.UserData["FixedWand"] and this.UserData["HasShiftClick"] and this.UserData["HasShiftClick"][this.UserData["FixedWand"][2]] then --固定的法杖必须是有选框才能判定
                    CurrentWand = this.UserData["FixedWand"][2]
                else                                                                                                                                    --否则就判断手持
                    local HeldWand = Compose(GetEntityHeldWand, GetPlayer)()
                    if HeldWand then
                        CurrentWand = HeldWand
                    end
                end
				if CurrentWand and this.UserData["HasShiftClick"] and this.UserData["HasShiftClick"][CurrentWand] then --必须是有选框的
					NewUseHistory(id)
					local HasShiftClick = this.UserData["HasShiftClick"][CurrentWand]
                    local min = HasShiftClick[2]
                    local max = HasShiftClick[3] or min
					if min == max then--必须是单选一格的情况下
						local wandData = GetWandData(CurrentWand)
                        local flag = InsertTableSpells(wandData, InputIsKeyDown(Key_z), id, min)
                        if flag then
							InitWand(wandData, CurrentWand)
							this.OnceCallOnExecute(function()
								RefreshHeldWands()
							end)
                        else
							GamePrint(GameTextGet("$wand_editor_spell_insert_error"))
						end
					end
				end
            elseif left_click and CTRL then --CTRL+左键
                local inventory_full = EntityGetChildWithName(GetPlayer(), "inventory_full")
                if inventory_full then
					NewUseHistory(id)
                    local px, py = GetPlayerXY()
                    local spell = CreateItemActionEntity(id, px, py)
                    EntitySetComponentsWithTagEnabled(spell, "enabled_in_world", false)
                    EntityAddChild(inventory_full, spell)
                    GamePrint(GameTextGetTranslatedOrNot(spellData[id].name),
                        GameTextGetTranslatedOrNot("$wand_editor_added_spell"))
                end
            elseif left_click and ALT then --ALT+左键收藏/删除法术
                if IsFavorite and Container ~= "HistorySpells" then
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
            elseif left_click and not UI.UserData["HasSpellMove"]and not this.GetNoMoveBool() then --纯左键
                this.UserData["SpellHoverEnable"] = false
                DrawFloatSpell(x, y, sprite, id)
				NewUseHistory(id)
            elseif left_click and UI.UserData["HasSpellMove"] then
                UI.UserData["HasSpellMove"] = false
                UI.UserData["FloatSpellID"] = nil
                UI.UserData["UpSpellIndex"] = nil
				this.UserData["SpellHoverEnable"] = true
            end
		end

		this.AddScrollImageItem(Container, sprite, function()--添加图片项目的回调绘制
			GuiZSetForNextWidget(this.gui, this.GetZDeep() + 2)
			GuiImage(this.gui, this.NewID(fastConcatStr("__SPELL_" , id , "_BG", GuiID)), -2, 0, "data/ui_gfx/inventory/full_inventory_box.png", 1, 1)
            local _, _, _, x, y, w, h = GuiGetPreviousWidgetInfo(this.gui)
            GuiZSetForNextWidget(this.gui, this.GetZDeep())
            GuiOptionsAddForNextWidget(this.gui, GUI_OPTION.Layout_NoLayouting)
            if not UI.GetPickerStatus("DisableSpellWobble") then
                GuiOptionsAddForNextWidget(this.gui, GUI_OPTION.DrawWobble) --让法术摇摆
            end
            local sw,sh = GuiGetImageDimensions(this.gui, sprite, 1)
			UI.MoveImageButton(fastConcatStr("__SPELL_", id, GuiID), x + (w-sw)/2, y + (h-sh)/2, sprite, nil, SpellHover, SpellCilck, true, true)--最后两个参数是不始终调用点击回调和禁止移动
			--绘制法术背景，深度要控制好

            GuiZSetForNextWidget(this.gui, this.GetZDeep() + 1)
			GuiOptionsAddForNextWidget(this.gui,GUI_OPTION.Layout_NoLayouting)
			GuiImage(this.gui, this.NewID(fastConcatStr("__SPELL_" , id , "_SPELLBG", GuiID)), x, y, SpellTypeBG[spellData[id].type], 1, 1)
        end)
		this.SetZDeep(ZDeepest)
	end
    for pos, id in pairs(spellTable) do
        if spellData[id] == nil then
            goto continue
        end
        SpellSlotDraw(pos, id, ContainerName, "spellTable")
        ::continue::
    end
	if UI.GetPickerStatus("SpellDepotHistoryMode") then
		local TableStr = ModSettingGet(ModID .. "SpellDepotHistoryData")
		if TableStr == nil then
			ModSettingSet(ModID .. "SpellDepotHistoryData", "return {}")
			LastHistoryTable = {}
        else
            LastHistoryTable = loadstring(TableStr)()
			for k,v in pairs(LastHistoryTable)do
				HistoryTableMap[v] = true
			end
		end
        for pos, id in pairs(LastHistoryTable) do
            if spellData[id] == nil then
                HistoryTableMap[id] = nil
				LastHistoryTable[pos] = nil
                goto continue
            end
            SpellSlotDraw(pos, id, "HistorySpells", "History")
            ::continue::
        end
		this.DrawScrollContainer("HistorySpells", false)
	end
    GuiZSetForNextWidget(this.gui, this.GetZDeep() + 1) --设置深度，确保行为正确
    this.DrawScrollContainer(ContainerName, true)
end

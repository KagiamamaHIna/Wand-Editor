dofile_once("mods/wand_editor/files/libs/fn.lua")
dofile_once("data/scripts/gun/gun_enums.lua")
local fastConcatStr = Cpp.ConcatStr
---@class Gui
local this = UI
local L_tostring = tostring
local L_GuiZSetForNextWidget = GuiZSetForNextWidget
local L_GuiImage = GuiImage
local L_GuiGetPreviousWidgetInfo = GuiGetPreviousWidgetInfo
local L_GuiOptionsAddForNextWidget = GuiOptionsAddForNextWidget
local L_GuiLayoutBeginHorizontal = GuiLayoutBeginHorizontal
local L_GuiText = GuiText
local L_GuiImageButton = GuiImageButton
local L_GuiLayoutEnd = GuiLayoutEnd
local L_SpellTypeBG = SpellTypeBG

local CopiedData = false

local CheckSpells = function(str)
    if HasEnds(str) then
        return false
    end
    local CheckFn = loadstring(str)
    if type(CheckFn) ~= "function" then
        return false
    end
    local fn = setfenv(CheckFn, {}) --设置环境 防止注入攻击
    local flag, result = pcall(fn)
    if not flag then
        return false
    end
    if type(result) ~= "table" then
        return false
    end
	return true,result
end

local function SpellPicker(ScrollID, id, wandEntity, wandData, spellData, k, v, isAlways)
	local BaseName = "Spell"
	if isAlways then
		BaseName = fastConcatStr(BaseName, "_isAlways")
	end
	local srcDeep = this.GetZDeep()
    local BGAlpha = 1
	if not isAlways then
		local BGAlphaKey = fastConcatStr(id , "LastWandContHoverAlpha" , L_tostring(k))
		local BGAlphaMaxKey = fastConcatStr(id , "LastWandContHoverMax" , L_tostring(k))
		if this.UserData[fastConcatStr(id , "LastWandContHover" , L_tostring(k))] and v == "nil" and (not isAlways) then --法术为空的时候才渐变
			if this.UserData[BGAlphaKey] == nil then                                   --格子渐变实现
				this.UserData[BGAlphaKey] = 1
				this.UserData[BGAlphaMaxKey] = 0.6
			elseif this.UserData[BGAlphaKey] > this.UserData[BGAlphaMaxKey] then
				this.UserData[BGAlphaKey] = this.UserData[BGAlphaKey] - 0.015
				this.UserData[BGAlphaMaxKey] = 0.6
			else
				this.UserData[BGAlphaKey] = this.UserData[BGAlphaKey] + 0.015
				this.UserData[BGAlphaMaxKey] = 1
			end
			BGAlpha = this.UserData[BGAlphaKey]
		else
			this.UserData[BGAlphaKey] = nil
			this.UserData[BGAlphaMaxKey] = nil
		end
	end

	L_GuiZSetForNextWidget(this.gui, this.GetZDeep())
    this.SetZDeep(this.GetZDeep() - 1)
	
	L_GuiImage(this.gui, this.NewID(fastConcatStr(id , BaseName, "full_BG" , L_tostring(k))), 0, 0,
        "data/ui_gfx/inventory/full_inventory_box.png", BGAlpha, 1)
	local click, _, hover, x, y = L_GuiGetPreviousWidgetInfo(this.gui)
	local CacheKey = fastConcatStr(id, "HoverCache")
	if this.UserData[CacheKey] == nil then
		local scale = this.GetScale()
		local _, my = InputGetMousePosOnScreen()
		my = my / scale
		local ScrollY = this.GetScrollY(ScrollID)
		local ScrollH = this.GetScrollHeight(ScrollID)
		local ScrollMarginY = this.GetScrollMY(ScrollID)
        if ScrollY and ScrollMarginY and (my < ScrollY - ScrollMarginY or my > ScrollY + ScrollH + ScrollMarginY) then
            this.UserData[CacheKey] = true
        else
			this.UserData[CacheKey] = this.UserData[CacheKey] or false
        end
		this.OnceCallOnExecute(function ()
			this.UserData[CacheKey] = nil
		end)
	end
	if this.UserData[CacheKey] then
		click = false
		hover = false
	end

	local highlight = false
    if this.UserData["HasShiftClick"][wandEntity] and this.UserData["HasShiftClick"][wandEntity][1] == id and (not isAlways) then --判断是否要高亮
        local HasShiftClick = this.UserData["HasShiftClick"][wandEntity]
        local min = HasShiftClick[2]
        local max = HasShiftClick[3] or min
        if max < min then --计算是否要高亮
            if k >= max and k <= min then
                highlight = true
            end
        else
            if k >= min and k <= max then
                highlight = true
            end
        end
        if highlight then
            L_GuiZSetForNextWidget(this.gui, this.GetZDeep())
            this.SetZDeep(this.GetZDeep() - 1)
            L_GuiImage(this.gui, this.NewID(fastConcatStr(id, "hgBG", L_tostring(k))), -22, 0,
                "mods/wand_editor/files/gui/images/highlight.png", BGAlpha, 1)
        end
    end
	if hover then
		if isAlways then
			if v ~= "nil" and not this.GetPickerStatus("DisableSpellHover") then
				this.BetterTooltips(function()
					HoverDarwSpellText(this, v.id, spellData[v.id],nil, GameTextGet("$wand_editor_always") .. L_tostring(k))
				end, this.GetZDeep()-114514, 8, 26)
			else
				OldGuiTooltip(this.gui, GameTextGet("$wand_editor_always") .. L_tostring(k), "")
			end
		else
			if v ~= "nil" and not this.GetPickerStatus("DisableSpellHover") then
				this.BetterTooltips(function()
					local text
					if v.uses_remaining ~= -1 then
						text = GameTextGet("$wand_editor_slot",L_tostring(k)).." ("..GameTextGet("$inventory_usesremaining").." : "..v.uses_remaining..")"
					else
						text = GameTextGet("$wand_editor_slot",L_tostring(k))
					end
					HoverDarwSpellText(this, v.id, spellData[v.id],v.uses_remaining, text)
				end,this.GetZDeep()-114514,8,26)
			else
                OldGuiTooltip(this.gui, GameTextGet("$wand_editor_slot", L_tostring(k)), "")
			end
		end
	end

    if v ~= "nil" and spellData[v.id] ~= nil then --绘制法术与背景
        L_GuiZSetForNextWidget(this.gui, this.GetZDeep())
        this.SetZDeep(this.GetZDeep() - 1)
        L_GuiImage(this.gui, this.NewID(fastConcatStr(id, BaseName, "BG", v.id, L_tostring(k))), -22, 0,
			L_SpellTypeBG[spellData[v.id].type],
            1, 1)
        L_GuiLayoutBeginHorizontal(this.gui, -20, 0, true, -20, 6) --使得正确的布局实现
        L_GuiZSetForNextWidget(this.gui, this.GetZDeep())
        this.SetZDeep(this.GetZDeep() - 1)
        if not this.GetPickerStatus("DisableSpellWobble") then
            L_GuiOptionsAddForNextWidget(this.gui, GUI_OPTION.DrawWobble)
        end
        L_GuiOptionsAddForNextWidget(this.gui, GUI_OPTION.AlwaysClickable)
        L_GuiImageButton(this.gui, this.NewID(fastConcatStr(id, BaseName, v.id, L_tostring(k))), 0, 2, "",
            spellData[v.id].sprite)
        if isAlways then
            L_GuiZSetForNextWidget(this.gui, this.GetZDeep())
            this.SetZDeep(this.GetZDeep() - 1)
            L_GuiImage(this.gui, this.NewID(fastConcatStr(id, BaseName, "Always", v.id, L_tostring(k))), 1, 0,
                "mods/wand_editor/files/gui/images/always_icon.png",
                1, 1)
        end
        if not isAlways and v ~= "nil" and v.uses_remaining ~= -1 then
            L_GuiZSetForNextWidget(this.gui, this.GetZDeep())
            this.SetZDeep(this.GetZDeep() - 1)
            L_GuiText(this.gui, 4, 2, L_tostring(v.uses_remaining), 1, "data/fonts/font_small_numbers.xml")
        end
        L_GuiLayoutEnd(this.gui)
    end
	if not isAlways then
		this.UserData[fastConcatStr(id , "LastWandContHover" , L_tostring(k))] = hover
        this.UserData["WandContainerHasHover"] = this.UserData["WandContainerHasHover"] or hover
	end
    if not hover then
        this.SetZDeep(srcDeep) --恢复深度以解决奇怪深度问题
        return
    end
	
    if not isAlways then
        local CurrentWand
        if this.UserData["FixedWand"] and this.UserData["HasShiftClick"][this.UserData["FixedWand"][2]] then --固定的法杖必须是有选框才能判定
            CurrentWand = this.UserData["FixedWand"][2]
        else                                                                                           --否则就判断手持
            local HeldWand = Compose(GetEntityHeldWand, GetPlayer)()
            if HeldWand then
                CurrentWand = HeldWand
            end
        end
        if (InputIsKeyDown(Key_LALT) or InputIsKeyDown(Key_RALT)) and click and this.UserData["HasShiftClick"][CurrentWand] then --批量添加始终
            local CurrentData = GetWandData(CurrentWand)
            local HasShiftClick = this.UserData["HasShiftClick"][CurrentWand]
            local min = HasShiftClick[2]
            local max = HasShiftClick[3] or min
            min = math.min(min, max)
            max = math.max(HasShiftClick[2], max)
            if min == max then --如果是单个选框的
                local spell = GetSpellID(CurrentData, min)
                if spell ~= "nil" then
                    PushAlwaysSpell(CurrentData, spell.id)
                    RemoveTableSpells(CurrentData, min)
                    InitWand(CurrentData, CurrentWand)
                end
            else --反之就是多个
                for i = min, max do
                    local spell = GetSpellID(CurrentData, i)
                    if spell ~= "nil" then
                        PushAlwaysSpell(CurrentData, spell.id)
                        RemoveTableSpells(CurrentData, i)
                    end
                end
                InitWand(CurrentData, CurrentWand)
            end
            this.UserData["HasShiftClick"][CurrentWand] = nil
            this.OnceCallOnExecute(function()
                RefreshHeldWands()
            end)
        elseif (InputIsKeyDown(Key_LALT) or InputIsKeyDown(Key_RALT)) and click and v ~= "nil" then --添加始终
            PushAlwaysSpell(wandData, v.id)
            RemoveTableSpells(wandData, k)
            InitWand(wandData, wandEntity)
            this.OnceCallOnExecute(function()
                RefreshHeldWands()
            end)
        elseif (InputIsKeyDown(Key_LSHIFT) or InputIsKeyDown(Key_RSHIFT)) and click then --框选法术
            local FixedWand
            if this.UserData["FixedWand"] then
                FixedWand = this.UserData["FixedWand"][2]
            end
            if this.UserData["HasShiftClick"][wandEntity] == nil then
                this.UserData["HasShiftClick"][wandEntity] = { id, k, nil }
                if FixedWand and this.UserData["HasShiftClick"][FixedWand] and FixedWand ~= wandEntity then
                    if this.UserData["HasShiftClick"][FixedWand][1] == "WandSpellViewer" then --判断id是为了看看需不需要设置
                        this.UserData["HasShiftClick"][FixedWand] = nil
                    end
                elseif FixedWand == wandEntity then                          --固定的法杖，等于传入的法杖实体的时候
                    local HeldWand = Compose(GetEntityHeldWand, GetPlayer)() --获取手持法杖
                    if HeldWand and HeldWand ~= wandEntity then
                        this.UserData["HasShiftClick"][HeldWand] = nil
                    end
                end
            elseif this.UserData["HasShiftClick"][wandEntity][2] == k or this.UserData["HasShiftClick"][wandEntity][1] ~= id or this.UserData["HasShiftClick"][wandEntity][3] == k then
                if this.UserData["HasShiftClick"][wandEntity][1] ~= id then --如果是id不相同，那么就要重新设置
                    this.UserData["HasShiftClick"][wandEntity][1] = id
                    this.UserData["HasShiftClick"][wandEntity][2] = k
                    this.UserData["HasShiftClick"][wandEntity][3] = nil
                    if FixedWand and FixedWand ~= wandEntity then --如果你看不懂没关系，你叫我来可能也要反应半天
                        this.UserData["HasShiftClick"][FixedWand] = nil
                    end
                else --如果是id相同且索引一致，那么就清空数据，代表取消
                    this.UserData["HasShiftClick"][wandEntity] = nil
                end
            else
                this.UserData["HasShiftClick"][wandEntity][3] = k
            end
            --多选跨法杖交换，恶心！
        elseif click and this.UserData["FloatSpellID"] == nil and (InputIsKeyDown(Key_LCTRL) or InputIsKeyDown(Key_RCTRL)) and next(this.UserData["HasShiftClick"]) then
            if this.UserData["HasShiftClick"][wandEntity] then --如果你手持的和点击的法杖实体是同一个
                local HasShiftClick = this.UserData["HasShiftClick"][wandEntity]
                local min = HasShiftClick[2]
                local max = HasShiftClick[3] or min
                min = math.min(min, max)
                max = math.max(HasShiftClick[2], max)
                local ThisK = k
                for i = min, max do
                    if ThisK > wandData.deck_capacity then
                        break
                    end
                    SwapSpellPos(wandData, i, ThisK)
                    ThisK = ThisK + 1
                end
                InitWand(wandData, wandEntity)
                this.UserData["HasShiftClick"][wandEntity] = nil
                this.OnceCallOnExecute(function()
                    RefreshHeldWands()
                end)
            elseif this.UserData["FixedWand"] then              --反之不同，需要判空
                local HeldWand = Compose(GetEntityHeldWand, GetPlayer)()
                local FixedWand = this.UserData["FixedWand"][2] --如果是跨法杖编辑，那么代表这个是必然存在的
                local HasShiftClick = this.UserData["HasShiftClick"][HeldWand] or
                this.UserData["HasShiftClick"][FixedWand]
                if HasShiftClick ~= nil then
                    local IsFixed = false
                    local OtherWand
                    if FixedWand == wandEntity then --如果点击法杖等于固定法杖，那么其他数据就是手持法杖
                        OtherWand = GetWandData(HeldWand)
                        IsFixed = true
                    else --否则是固定法杖
                        OtherWand = GetWandData(FixedWand)
                    end
                    --如果没有问题(Bug)，那么应该只有一个是真（即有数据
                    local min = HasShiftClick[2]
                    local max = HasShiftClick[3] or min
                    min = math.min(min, max)
                    max = math.max(HasShiftClick[2], max)
                    local ThisK = k
                    for i = min, max do                                     --i是原始位置，k是目标位置
                        if i > OtherWand.deck_capacity or ThisK > wandData.deck_capacity then --超出容量就什么都不做
                            break
                        end
                        Swap2InputSpellPos(wandData, OtherWand, ThisK, i)
                        ThisK = ThisK + 1
                    end
                    if IsFixed then
                        InitWand(wandData, wandEntity)
                        InitWand(OtherWand, HeldWand)
                    else
                        InitWand(wandData, wandEntity)
                        InitWand(OtherWand, FixedWand)
                    end
                    this.UserData["HasShiftClick"][HeldWand] = nil
                    this.UserData["HasShiftClick"][FixedWand] = nil
                    this.OnceCallOnExecute(function()
                        RefreshHeldWands()
                    end)
                end
            end
        elseif click and this.UserData["FloatSpellID"] ~= nil then
            if this.UserData["UpSpellIndex"] ~= nil and v ~= "nil" then --如果存在键，则代表这是一次交换操作
                local i = this.UserData["UpSpellIndex"][1]
                local OtherWand = this.UserData["UpSpellIndex"][3]
                if OtherWand == wandEntity then --如果是同一实体
                    SetTableSpells(wandData, v.id, i, v.uses_remaining, false)
                else                --刷新另一根法杖
                    local OtherWandData = this.UserData["UpSpellIndex"][2]
                    SetTableSpells(OtherWandData, v.id, i, v.uses_remaining, false)
                    InitWand(OtherWandData, this.UserData["UpSpellIndex"][3])
                end --刷新手持法杖 这一步相当于交换
                SetTableSpells(wandData, this.UserData["FloatSpellID"], k, this.UserData["UpSpellIndex"][4], false)
                InitWand(wandData, wandEntity)
            else                          --当前法杖的
                local uses_remaining
                if this.UserData["UpSpellIndex"] then --如果有记录的话就赋值使用次数
                    uses_remaining = this.UserData["UpSpellIndex"][4]
                end
                SetTableSpells(wandData, this.UserData["FloatSpellID"], k, uses_remaining, false)
                InitWand(wandData, wandEntity)
            end
            this.UserData["UpSpellIndex"] = nil
            this.UserData["FloatSpellID"] = nil
            this.OnceCallOnExecute(function()
                RefreshHeldWands()
            end)
            this.UserData["SpellHoverEnable"] = true
        elseif v ~= "nil" and click then --移动法术
            if not this.GetNoMoveBool() then
                this.UserData["SpellHoverEnable"] = false
                DrawFloatSpell(x, y, spellData[v.id].sprite, v.id)
                if this.UserData["UpSpellIndex"] == nil then --记录上次的键等数据
                    this.UserData["UpSpellIndex"] = { k, wandData, wandEntity, v.uses_remaining }
                end
                RemoveTableSpells(wandData, k)
                InitWand(wandData, wandEntity)
                this.OnceCallOnExecute(function()
                    RefreshHeldWands()
                end)
            end
		--[[
        elseif (InputIsKeyDown(Key_LCTRL) or InputIsKeyDown(Key_RCTRL)) and (InputIsKeyDown(Key_c) or InputIsKeyDown(Key_x)) and this.UserData["HasShiftClick"][CurrentWand] then
            if not CopiedData then
                local CurrentData = GetWandData(CurrentWand)
                local HasShiftClick = this.UserData["HasShiftClick"][CurrentWand]
                local min = HasShiftClick[2]
                local max = HasShiftClick[3] or min
                min = math.min(min, max)
                max = math.max(HasShiftClick[2], max)
                local DownX = InputIsKeyDown(Key_x)
                local T = {}
                for i = min, max do
                    T[#T + 1] = GetSpellID(CurrentData, i)
                    if DownX then
                        RemoveTableSpells(CurrentData, i)
                    end
                end
                if DownX then
                    InitWand(CurrentData, CurrentWand)
					this.OnceCallOnExecute(function()
						RefreshHeldWands()
					end)
                end
                Cpp.SetClipboard(Cpp.ConcatStr("return {\n", SerializeTable(T), "}"))
                CopiedData = true
				this.UserData["HasShiftClick"][CurrentWand] = nil
            end
		elseif (InputIsKeyDown(Key_LCTRL) or InputIsKeyDown(Key_RCTRL)) and InputIsKeyJustDown(Key_v) and hover then
            local ClipboardData = Cpp.GetClipboard()
            local flag, t = CheckSpells(ClipboardData)
            if flag then
                for i = #t, 1, -1 do
                    InsertTableSpells(wandData, t[i].id, k)
                end
                InitWand(wandData, wandEntity)
				this.OnceCallOnExecute(function()
					RefreshHeldWands()
				end)
            end
        else
			CopiedData = false]]
        end
    else --是始终施放法术的操作
        if hover and InputIsKeyDown(Key_BACKSPACE) then
            if this.UserData["AlwaysClickFr"] == nil then
                this.UserData["AlwaysClickFr"] = 45
            elseif this.UserData["AlwaysClickFr"] > 0 then
                this.UserData["AlwaysClickFr"] = this.UserData["AlwaysClickFr"] - 1
            end
            if this.UserData["AlwaysClickFr"] == 45 or this.UserData["AlwaysClickFr"] == 0 then
                RemoveTableAlwaysSpells(wandData, k)
                InitWand(wandData, wandEntity)
                this.OnceCallOnExecute(function()
                    RefreshHeldWands()
                end)
            end
        elseif click and this.UserData["FloatSpellID"] == nil then
            if not this.GetNoMoveBool() then
                this.UserData["SpellHoverEnable"] = false
                DrawFloatSpell(x, y, spellData[v.id].sprite, v.id)
                --不记录上次数据
                RemoveTableAlwaysSpells(wandData, k)
                InitWand(wandData, wandEntity)
                this.OnceCallOnExecute(function()
                    RefreshHeldWands()
                end)
            end
        elseif not InputIsKeyDown(Key_BACKSPACE) then
            this.UserData["AlwaysClickFr"] = nil
        end
    end
	if not isAlways then
        if hover and InputIsKeyJustDown(Key_BACKSPACE) and highlight then --按下退格键多选删除法术
			local HasShiftClick = this.UserData["HasShiftClick"][wandEntity]
			local min = HasShiftClick[2]
			local max = HasShiftClick[3] or min
			min = math.min(min, max)
            max = math.max(HasShiftClick[2], max)
			for i = min, max do
				RemoveTableSpells(wandData, i)
			end
			InitWand(wandData, wandEntity)
			this.UserData["HasShiftClick"][wandEntity] = nil
			this.OnceCallOnExecute(function()
				RefreshHeldWands()
			end)
		elseif hover and InputIsKeyJustDown(Key_BACKSPACE) and v ~= "nil" then --按下退格键删除法术
			RemoveTableSpells(wandData, k)
			InitWand(wandData, wandEntity)
			this.OnceCallOnExecute(function()
				RefreshHeldWands()
			end)
		end
	end
	this.SetZDeep(srcDeep) --恢复深度以解决奇怪深度问题
end

local LastWand
local LastCapacity = 0
function DrawWandContainer(wandEntity, spellData)
    local srcZDeep = this.GetZDeep()
	this.SetZDeep(srcZDeep + 1000)
	if this.UserData["HasShiftClick"] == nil then
		this.UserData["HasShiftClick"] = {}
	else
		for entity, _ in pairs(this.UserData["HasShiftClick"]) do
			if not EntityGetIsAlive(entity) then --垃圾回收
				this.UserData["HasShiftClick"][entity] = nil
			end
		end
	end
	local Skip = false --是否跳过
	if wandEntity == nil then
		Skip = true
	end
    local wandData = GetWandData(wandEntity)
	
	local HeldWand = Compose(GetEntityHeldWand, GetPlayer)()
	local FixedWand
	if this.UserData["FixedWand"] then
		FixedWand = this.UserData["FixedWand"][2]
	end
	if HeldWand and HeldWand ~= FixedWand then --阻止同时出现多个多选框
		if this.UserData["HasShiftClick"][HeldWand] and this.UserData["HasShiftClick"][FixedWand] and this.UserData["HasShiftClick"][FixedWand][1] == "WandSpellViewer" then
			this.UserData["HasShiftClick"][HeldWand] = nil
		end
	end
	if wandData == nil then
		Skip = true
	end
	local TrueWidth = this.ScreenWidth - 20
	local HScrollX = 10
	local HScrollY = this.ScreenHeight - 38.5
	local HScrollWidth = this.GetHScrollWidth("WandContainer")
	if not Skip then
        if HScrollWidth == nil or LastWand ~= wandEntity or this.UserData["NextResetHScroll"] then --自动居中
            HScrollX = this.ScreenWidth * 2
            HScrollY = this.ScreenHeight * 2
            this.UserData["NextResetHScroll"] = false
        elseif HScrollWidth < TrueWidth and HScrollWidth ~= 0 then
            TrueWidth = HScrollWidth
            HScrollX = this.ScreenWidth * 0.5 - HScrollWidth / 2
        end
        local Ability = EntityGetFirstComponentIncludingDisabled(wandEntity, "AbilityComponent")
		local thisDecks = ComponentObjectGetValue2(Ability, "gun_config", "deck_capacity")
        if LastCapacity ~= thisDecks then --如果不一致就刷新数据
			this.UserData["NextResetHScroll"] = true
			this.OnceCallOnExecute(function ()
				this.ResetHScrollSlider("WandContainer")
			end)
        end
		if wandData then--执行顺序问题，先放这里防止始终数量更改
			LastCapacity = thisDecks
		end
	end


	this.HorizontalScroll("WandContainer", HScrollX, HScrollY, TrueWidth, 20, false, 0, 0)

	local ViewerHover = function()
		local _, _, hover = L_GuiGetPreviousWidgetInfo(this.gui)
		local tip = GameTextGet("$wand_editor_wand_spell_viewer_tip_close")
        if this.UserData["FixedWand"] then
            tip = GameTextGet("$wand_editor_wand_spell_viewer_tip_open")
        end
		GuiTooltip(this.gui, tip, "")
		if hover or this.UserData["FixedWand"] then
			local ViewerWandData = wandData
			local ViewerWandEntity = wandEntity
			if this.UserData["FixedWand"] then
				ViewerWandData = this.UserData["FixedWand"][1]
				ViewerWandEntity = this.UserData["FixedWand"][2]
			end
			if ViewerWandData == nil then --使用遁入虚空会导致法杖id刷新，所以此时无法获得法杖最新数据，因此需要判空
				return
			end
			this.ScrollContainer("WandSpellViewerContainer", 250, 64, this.ScreenWidth - 250 - 40,
				this.ScreenHeight - 60 - 70, nil, 0, 1.14)

			for k, v in pairs(ViewerWandData.spells.always) do
				this.AddScrollImageItem("WandSpellViewerContainer", "data/ui_gfx/inventory/full_inventory_box.png",
					function()
						SpellPicker("WandSpellViewerContainer", "WandSpellViewer", ViewerWandEntity, ViewerWandData, spellData, k, v, true)
					end)
			end
			for k, v in pairs(ViewerWandData.spells.spells) do
				this.AddScrollImageItem("WandSpellViewerContainer", "data/ui_gfx/inventory/full_inventory_box.png",
					function()
						SpellPicker("WandSpellViewerContainer", "WandSpellViewer", ViewerWandEntity, ViewerWandData, spellData, k, v)
					end)
			end
			if this.UserData["FixedWand"] then
                this.UserData["FixedWand"][1] = GetWandData(ViewerWandEntity)
			end
			L_GuiZSetForNextWidget(this.gui, this.GetZDeep() + 1)
			this.DrawScrollContainer("WandSpellViewerContainer", true)
		end
	end
	local ViewerClick = function(left_click)
        if left_click or (InputIsKeyDown(Key_GRAVE) and this.UserData["ViewerCKeyDown"] == nil) then --点击左键就存储数据
			this.UserData["ViewerCKeyDown"] = true
            if this.UserData["FixedWand"] == nil then
                this.UserData["FixedWand"] = { wandData, wandEntity }
            else
                this.UserData["FixedWand"] = nil
            end
        elseif not InputIsKeyDown(Key_GRAVE) and this.UserData["ViewerCKeyDown"] then
			RestoreInput()
			this.UserData["ViewerCKeyDown"] = nil
        end
		if left_click then
			GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", GameGetCameraPos())
		end
	end
	--为了实现，满足条件下即使玩家也不拿着法杖，也会绘制这些控件
	if not Skip then
		L_GuiZSetForNextWidget(this.gui, this.GetZDeep() + 1)
		this.MoveImageButton("WandSpellViewerBTN", HScrollX + 3, this.ScreenHeight - 53.5,
			"mods/wand_editor/files/gui/images/wand_spell_viewer.png", nil, ViewerHover, ViewerClick, nil, true)
	elseif this.UserData["FixedWand"] then
		L_GuiZSetForNextWidget(this.gui, this.GetZDeep() + 1)
		this.MoveImageButton("WandSpellViewerBTN", 235, 64, "mods/wand_editor/files/gui/images/wand_spell_viewer.png", nil,
			ViewerHover, ViewerClick, nil, true)
	end
    if not Skip then --绘制法术编辑栏
        for k, v in pairs(wandData.spells.always) do
            this.AddHScrollItem("WandContainer", function()
                SpellPicker("WandContainer", "WandContainer", wandEntity, wandData, spellData, k, v, true)
            end)
        end
        for k, v in pairs(wandData.spells.spells) do
            this.AddHScrollItem("WandContainer", function()
                SpellPicker("WandContainer", "WandContainer", wandEntity, wandData, spellData, k, v)
            end)
        end

        this.DarwHorizontalScroll("WandContainer")
        LastWand = wandEntity
    end
	this.SetZDeep(srcZDeep)
end

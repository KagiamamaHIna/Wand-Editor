dofile_once("mods/wand_editor/files/libs/fn.lua")
dofile_once("data/scripts/gun/gun_enums.lua")
local function SpellPicker(this, id, wandEntity, wandData, spellData, k, v, highlight)
	local srcDeep = this.GetZDeep()
	local BGAlpha = 1
	local BGAlphaKey = id.."LastWandContHoverAlpha" .. tostring(k)
	local BGAlphaMaxKey = id.."LastWandContHoverMax" .. tostring(k)
    if this.UserData[id .. "LastWandContHover" .. tostring(k)] and v == "nil" then --法术为空的时候才渐变
        if this.UserData[BGAlphaKey] == nil then                              --格子渐变实现
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
	GuiZSetForNextWidget(this.gui, this.GetZDeep())
	this.SetZDeep(this.GetZDeep() - 1)
	GuiImage(this.gui, this.NewID(id.."BG" .. tostring(k)), 0, 0,
        "data/ui_gfx/inventory/full_inventory_box.png", BGAlpha, 1)
    if highlight then
		GuiZSetForNextWidget(this.gui, this.GetZDeep())
		this.SetZDeep(this.GetZDeep() - 1)
		GuiImage(this.gui, this.NewID(id.."hgBG" .. tostring(k)), -22, 0,
			"mods/wand_editor/files/gui/images/highlight.png", BGAlpha, 1)
	end

    local click, _, hover, x, y = GuiGetPreviousWidgetInfo(this.gui)
	if click and this.UserData["FloatSpellID"] ~= nil then
		if this.UserData["UpSpellIndex"] ~= nil and v ~= "nil" then --如果存在键，则代表这是一次交换操作
			local i = this.UserData["UpSpellIndex"][1]
			local AntherWand = this.UserData["UpSpellIndex"][3]
			if AntherWand == wandEntity then --如果是同一实体
				SetTableSpells(wandData, v.id, i, v.uses_remaining, false)
			else              --刷新另一根法杖
				local AntherWandData = this.UserData["UpSpellIndex"][2]
				SetTableSpells(AntherWandData, v.id, i, v.uses_remaining, false)
				InitWand(AntherWandData, this.UserData["UpSpellIndex"][3])
			end --刷新手持法杖 这一步相当于交换
			SetTableSpells(wandData, this.UserData["FloatSpellID"], k, this.UserData["UpSpellIndex"][4], false)
			InitWand(wandData, wandEntity)
		else --当前法杖的
			local uses_remaining
			if this.UserData["UpSpellIndex"] then--如果有记录的话就赋值使用次数
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
	elseif v ~= "nil" and click then--移动法术
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
	end
	GuiTooltip(this.gui, tostring(k), "")
	this.UserData[id.."LastWandContHover" .. tostring(k)] = hover
	this.UserData["WandContainerHasHover"] = this.UserData["WandContainerHasHover"] or hover
	if hover and InputIsKeyDown(Key_BACKSPACE) and v ~= "nil" then
		RemoveTableSpells(wandData, k)
		InitWand(wandData, wandEntity)
		this.OnceCallOnExecute(function()
			RefreshHeldWands()
		end)
	end
    if v ~= "nil" then --绘制法术与背景
        GuiZSetForNextWidget(this.gui, this.GetZDeep())
        this.SetZDeep(this.GetZDeep() - 1)
        GuiImage(this.gui, this.NewID(id .. "SpellBG" .. v.id .. tostring(k)), -22, 0, SpellTypeBG[spellData[v.id].type],
            1, 1)
        GuiLayoutBeginHorizontal(this.gui, -20, 0, true, -20, 6) --使得正确的布局实现
        GuiZSetForNextWidget(this.gui, this.GetZDeep())
        this.SetZDeep(this.GetZDeep() - 1)
        GuiOptionsAddForNextWidget(this.gui, GUI_OPTION.DrawWobble)
        GuiOptionsAddForNextWidget(this.gui, GUI_OPTION.AlwaysClickable)
        GuiImageButton(this.gui, this.NewID(id .. "Spell" .. v.id .. tostring(k)), 0, 2, "", spellData[v.id].sprite)
        GuiLayoutEnd(this.gui)
    end
	this.SetZDeep(srcDeep)--恢复深度以解决奇怪深度问题
end

local LastCapacity = 0
function DrawWandContainer(this, wandEntity, spellData)
	local Skip = false--是否跳过
    if wandEntity == nil then
        Skip = true
    end
    local wandData = GetWandData(wandEntity)
    if wandData == nil then
        Skip = true
    end
	local TrueWidth = this.ScreenWidth - 20
	local HScrollX = 10
	local HScrollWidth = this.GetHScrollWidth("WandContainer")
	if not Skip then
        if HScrollWidth == nil then --自动居中
            TrueWidth = 0
            HScrollX = this.ScreenWidth * 2
        elseif HScrollWidth < TrueWidth and HScrollWidth ~= 0 then
            TrueWidth = HScrollWidth
            HScrollX = this.ScreenWidth * 0.5 - HScrollWidth / 2
        end
		if LastCapacity ~= wandData.deck_capacity then --如果不一致就刷新数据
			this.ResetHScrollSlider("WandContainer")
		end
	end


	local HasViewerHover = false
    this.HorizontalScroll("WandContainer", HScrollX, this.ScreenHeight - 38.5, TrueWidth, 20, false, 0, 0)

    local ViewerHover = function()
        local _, _, hover = GuiGetPreviousWidgetInfo(this.gui)
		local tip = GameTextGetTranslatedOrNot("$wand_editor_wand_spell_viewer_tip_close")
		if this.UserData["FixedWand"] then
			tip = GameTextGetTranslatedOrNot("$wand_editor_wand_spell_viewer_tip_open")
		end
        GuiTooltip(this.gui, tip, "")
        if hover or this.UserData["FixedWand"] then
			HasViewerHover = true
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
			if this.UserData["WandContainerHasHover"] == nil or this.UserData["WandContainerHasHover"] then
				this.UserData["WandContainerHasHover"] = false
			end
            for k, v in pairs(ViewerWandData.spells.spells) do
                this.AddScrollImageItem("WandSpellViewerContainer", "data/ui_gfx/inventory/full_inventory_box.png",
                    function()
                        SpellPicker(this, "WandSpellViewer", ViewerWandEntity, ViewerWandData, spellData, k, v)
                    end)
            end
			if this.UserData["FixedWand"] then
				this.UserData["FixedWand"][1] = GetWandData(ViewerWandEntity)
			end
			GuiZSetForNextWidget(this.gui, this.GetZDeep() + 1)
            this.DrawScrollContainer("WandSpellViewerContainer")
        end
    end
    local ViewerClick = function(left_click)
        if left_click then --点击左键就存储数据
            if this.UserData["FixedWand"] == nil then
                this.UserData["FixedWand"] = { wandData, wandEntity }
            else
                this.UserData["FixedWand"] = nil
            end
            GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", GameGetCameraPos())
        end
    end
	--为了实现，满足条件下即使玩家也不拿着法杖，也会绘制这些控件
    if not Skip then
		GuiZSetForNextWidget(this.gui, this.GetZDeep() + 1)
		this.MoveImageButton("WandSpellViewer", HScrollX+3, this.ScreenHeight - 53.5, "mods/wand_editor/files/gui/images/wand_spell_viewer.png", nil, ViewerHover, ViewerClick, nil, true)
    elseif this.UserData["FixedWand"] then
		GuiZSetForNextWidget(this.gui, this.GetZDeep() + 1)
		this.MoveImageButton("WandSpellViewer", 235, 64, "mods/wand_editor/files/gui/images/wand_spell_viewer.png", nil, ViewerHover, ViewerClick, nil, true)
	end
	if not Skip then--绘制法术编辑栏
		if this.UserData["WandContainerHasHover"] == nil or (not HasViewerHover) then
			this.UserData["WandContainerHasHover"] = false
		end
		for k, v in pairs(wandData.spells.spells) do
			this.AddHScrollItem("WandContainer", function()
				SpellPicker(this, "WandContainer", wandEntity, wandData, spellData, k, v)
			end)
		end
		
		this.DarwHorizontalScroll("WandContainer")
		LastCapacity = wandData.deck_capacity
	end
end

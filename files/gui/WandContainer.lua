dofile_once("mods/wand_editor/files/libs/fn.lua")
dofile_once("data/scripts/gun/gun_enums.lua")

local LastCapacity = 0
function DrawWandContainer(this, wandEntity, spellData)
    if wandEntity == nil then
        return
    end
    local wandData = GetWandData(wandEntity)
    if LastCapacity ~= wandData.deck_capacity then --如果不一致就刷新数据
        this.ResetHScrollSlider("WandContainer")
    end
	local TrueWidth = this.ScreenWidth - 20
	local HScrollX = 10
	local HScrollWidth = this.GetHScrollWidth("WandContainer")
	if HScrollWidth == nil then--自动居中
		TrueWidth = 0
		HScrollX = this.ScreenWidth * 2
	elseif HScrollWidth < TrueWidth and HScrollWidth ~= 0 then
		TrueWidth = HScrollWidth
		HScrollX = this.ScreenWidth*0.5 - HScrollWidth/2
	end
    this.HorizontalScroll("WandContainer", HScrollX, this.ScreenHeight - 42.5, TrueWidth, 20, false, 0, 0)
	this.UserData["WandContainerHasHover"] = false
    for k, v in pairs(wandData.spells.spells) do
        this.AddHScrollItem("WandContainer", function(NotOverflows)
            GuiZSetForNextWidget(this.gui, this.GetZDeep() - 1)
            this.SetZDeep(this.GetZDeep() - 1)
            local BGAlpha = 1
            local BGAlphaKey = "LastWandContHoverAlpha" .. tostring(k)
            local BGAlphaMaxKey = "LastWandContHoverMax" .. tostring(k)
            if this.UserData["LastWandContHover" .. tostring(k)] and v == "nil" then --法术为空的时候才渐变
                if this.UserData[BGAlphaKey] == nil then                             --格子渐变实现
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
            GuiImage(this.gui, this.NewID("WandContainerBG" .. tostring(k)), 0, 0,
                "data/ui_gfx/inventory/full_inventory_box.png", BGAlpha, 1)
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
                    SetTableSpells(wandData, this.UserData["FloatSpellID"], k, nil, false)
                    InitWand(wandData, wandEntity)
                end
                this.UserData["UpSpellIndex"] = nil
                this.UserData["FloatSpellID"] = nil
                this.OnceCallOnExecute(function()
                    RefreshHeldWands()
                end)
                this.UserData["SpellHoverEnable"] = true
            elseif v ~= "nil" and click then
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
            this.UserData["LastWandContHover" .. tostring(k)] = hover
            this.UserData["WandContainerHasHover"] = this.UserData["WandContainerHasHover"] or hover
            if v ~= "nil" then --绘制法术与背景
                GuiZSetForNextWidget(this.gui, this.GetZDeep() - 1)
                this.SetZDeep(this.GetZDeep() - 1)
                GuiImage(this.gui, this.NewID("WandContainerSpellBG" .. v.id), -22, 0, SpellTypeBG[spellData[v.id].type],
                    1, 1)
                GuiLayoutBeginHorizontal(this.gui, -20, 0, true, -20) --使得正确的布局实现
                GuiZSetForNextWidget(this.gui, this.GetZDeep() - 1)
                this.SetZDeep(this.GetZDeep() - 1)
                GuiOptionsAddForNextWidget(this.gui, GUI_OPTION.DrawWobble)
                GuiImageButton(this.gui, this.NewID("WandContainerSpell" .. v.id), 0, 2, "", spellData[v.id].sprite)
                GuiLayoutEnd(this.gui)
            end
        end)
    end
	
	this.DarwHorizontalScroll("WandContainer")
    LastCapacity = wandData.deck_capacity
end

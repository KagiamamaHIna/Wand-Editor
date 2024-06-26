local GetHeldWand = Compose(GetEntityHeldWand, GetPlayer)
local data = dofile_once("mods/wand_editor/files/gui/GetSpellData.lua") --读取法术数据
local spellData = data[1]
local TypeToSpellList = data[2]
local function ClickSound()
	GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", GameGetCameraPos())
end

---返回法杖仓库大小
---@return integer
local function GetWandDepotSize()
	return ModSettingGet(ModID .. "WandDepotSize")
end

--设置法杖仓库大小(不影响实际，单纯的设置)
local function SetWandDepotSize(num)
	ModSettingSet(ModID .. "WandDepotSize", num)
end

---获得法杖仓库表
---@param index integer
---@return table
local function GetWandDepot(index)
	local size = GetWandDepotSize()
	if index <= size then
		return Compose(loadstring, ModSettingGet)(ModID .. "WandDepot" .. tostring(index))()
	end
	error("wand depot index out of bounds:" .. tostring(index))
	return {}
end

---设置法杖仓库表
---@param t table
---@param index integer
local function SetWandDepotLua(t, index)
	local size = GetWandDepotSize()
	if index <= size then
		ModSettingSet(ModID .. "WandDepot" .. tostring(index), "return {\n" .. SerializeTable(t) .. "}")
	else
		error("wand depot index out of bounds" .. tostring(index))
	end
end

local function NewWandDepot()
	local index = GetWandDepotSize()
	SetWandDepotSize(index + 1)
	index = index + 1
	ModSettingSet(ModID .. "WandDepot" .. tostring(index), "return {}")
	return {}
end

local function RemoveWandDepot(index)
	local max = GetWandDepotSize()
	for i = index, max - 1 do
		SetWandDepotLua(GetWandDepot(i + 1), i)
	end
	ModSettingRemove(ModID .. "WandDepot" .. tostring(max))
	SetWandDepotSize(max - 1)
end

local RowMax = 12
local ColMax = 8
local TableMax = RowMax * ColMax
local RowGap = 23
local ColGap = 23
local SlotBG = "data/ui_gfx/inventory/full_inventory_box.png"
local HLSlotBG = "data/ui_gfx/inventory/full_inventory_box_highlight.png"
---绘制法杖格
---@param id string
---@param k integer
---@param wand Wand
local function DrawWandSlot(id, k, wand)
	local sprite
	local s = strip(wand.sprite_file)
	if string.sub(s, #s - 3) == ".xml" then
		local SpriteXml = ParseXmlAndBase(wand.sprite_file)
		sprite = SpriteXml.attr.filename
	else
		sprite = wand.sprite_file
	end
	k = k - 1
	local thisSlot
	if UI.UserData["WandDepotKHighlight"] == k then
		thisSlot = HLSlotBG
	else
		thisSlot = SlotBG
	end
	local column = math.floor(k % (RowMax))
	local row = math.floor(k / (RowMax))
	local x = ColGap * column
	local y = row * RowGap
	GuiZSetForNextWidget(UI.gui, UI.GetZDeep() - 1)
	local left_click = GuiImageButton(UI.gui, UI.NewID(id .. tostring(k) .. "BG"), 0 + x, 12 + y, "", thisSlot)
	local _, _, hover = GuiGetPreviousWidgetInfo(UI.gui)
	if hover then
		local rightMargin = 70
		local function NewLine(str1, str2, ShowFrTran)
			local text = GameTextGetTranslatedOrNot(str1)
			local w = GuiGetTextDimensions(UI.gui, text)
			GuiLayoutBeginHorizontal(UI.gui, 0, 0, true, 2, -1)
			GuiText(UI.gui, 0, 0, text)
			GuiRGBAColorSetForNextWidget(UI.gui, 255, 222, 173, 255)
			GuiText(UI.gui, rightMargin - w, 0, str2)
			GuiLayoutEnd(UI.gui)
		end
		local SecondWithSign = Compose(NumToWithSignStr, tonumber, FrToSecondStr)
		UI.tooltips(function()
			GuiLayoutBeginVertical(UI.gui, 0, 0, true)
			if InputIsKeyDown(Key_LCTRL) or InputIsKeyDown(Key_RCTRL) then
				local shuffle
				if wand.shuffle_deck_when_empty then
					shuffle = GameTextGet("$menu_yes")
				else
					shuffle = GameTextGet("$menu_no")
				end
				NewLine("$inventory_shuffle", shuffle)
				NewLine("$inventory_actionspercast", wand.actions_per_round)
				NewLine("$inventory_castdelay", SecondWithSign(wand.fire_rate_wait) .. "s(" .. wand.fire_rate_wait ..
				"f)")
				NewLine("$inventory_rechargetime", SecondWithSign(wand.reload_time) .. "s(" .. wand.reload_time .. "f)")
				NewLine("$inventory_manamax", math.floor(wand.mana_max))
				NewLine("$inventory_manachargespeed", math.floor(wand.mana_charge_speed))
				NewLine("$inventory_capacity", wand.deck_capacity)
				NewLine("$inventory_spread", wand.spread_degrees .. GameTextGet("$wand_editor_deg"))
				NewLine("$wand_editor_speed_multiplier", "x"..string.format("%.8f",wand.speed_multiplier))
			else
				GuiLayoutBeginHorizontal(UI.gui, 0, 0, true)
				for i = 1, #wand.spells.always do
					local v = wand.spells.always[i]
					GuiZSetForNextWidget(UI.gui, UI.GetZDeep() - 101)
					GuiImage(UI.gui, UI.NewID(id .. "always_full_BG" .. tostring(i)), 0, 0,
						"data/ui_gfx/inventory/full_inventory_box.png", 1, 0.5)
					local _, _, _, weigthX, _, weigthW = GuiGetPreviousWidgetInfo(UI.gui)
                    if spellData[v.id] ~= nil then --判空，防止法术数据异常
                        GuiZSetForNextWidget(UI.gui, UI.GetZDeep() - 102)
                        GuiImage(UI.gui, UI.NewID(id .. v.id .. "always" .. tostring(i)), -12, 0,
                            SpellTypeBG[spellData[v.id].type],
                            1, 0.5)
                        GuiLayoutBeginHorizontal(UI.gui, -11, 0, true, -8, 4) --使得正确的布局实现
                        GuiZSetForNextWidget(UI.gui, UI.GetZDeep() - 103)
                        GuiImage(UI.gui, UI.NewID(id .. v.id .. "always_spell" .. tostring(i) .. "BG"), 0, 1,
                            spellData[v.id].sprite, 1, 0.5)

                        GuiZSetForNextWidget(UI.gui, UI.GetZDeep() - 104)
                        GuiImage(UI.gui, UI.NewID(id .. v.id .. "Always_icon" .. tostring(k)), 0, 0,
                            "mods/wand_editor/files/gui/images/always_icon.png",
                            1, 0.5)
                        GuiLayoutEnd(UI.gui)
                    end
					if weigthX + weigthW >= UI.ScreenWidth - 80 then
						GuiLayoutEnd(UI.gui)
						GuiLayoutBeginHorizontal(UI.gui, 0, 0, true)
					end
				end
				for i = 1, #wand.spells.spells do
					local v = wand.spells.spells[i]
					GuiZSetForNextWidget(UI.gui, UI.GetZDeep() - 101)
					GuiImage(UI.gui, UI.NewID(id .. "full_BG" .. tostring(i)), 0, 0,
						"data/ui_gfx/inventory/full_inventory_box.png", 1, 0.5)
					local _, _, _, weigthX, _, weigthW = GuiGetPreviousWidgetInfo(UI.gui)
                    if v ~= "nil" and spellData[v.id] ~= nil then --判空，防止法术数据异常
                        GuiZSetForNextWidget(UI.gui, UI.GetZDeep() - 102)
                        GuiImage(UI.gui, UI.NewID(id .. v.id .. tostring(i) .. "BG"), -12, 0,
                            SpellTypeBG[spellData[v.id].type],
                            1, 0.5)
                        GuiLayoutBeginHorizontal(UI.gui, -11, 0, true, -8, 4) --使得正确的布局实现
                        GuiZSetForNextWidget(UI.gui, UI.GetZDeep() - 103)
                        GuiImage(UI.gui, UI.NewID(id .. v.id .. "spell" .. tostring(i)), 0, 1, spellData[v.id].sprite, 1,
                            0.5)
                        GuiLayoutEnd(UI.gui)
                    end
					if weigthX + weigthW >= UI.ScreenWidth - 80 then
						GuiLayoutEnd(UI.gui)
						GuiLayoutBeginHorizontal(UI.gui, 0, 0, true)
					end
				end
				GuiLayoutEnd(UI.gui)
				GuiColorSetForNextWidget(UI.gui, 0.5, 0.5, 0.5, 1.0)
				GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_wand_depot_wand_desc"))
			end
			GuiLayoutEnd(UI.gui)
		end, UI.GetZDeep() - 100, 10)
	end
	if left_click then
		if UI.UserData["WandDepotKHighlight"] == k then
			UI.UserData["WandDepotKHighlight"] = nil
		else
			UI.UserData["WandDepotKHighlight"] = k
		end
	end
	GuiZSetForNextWidget(UI.gui, UI.GetZDeep() - 2)
	GuiImage(UI.gui, UI.NewID(id .. tostring(k)), 5 + x, 22 + y, sprite, 1, 1, 0,
		math.rad(-57.5))
end

function WandDepotCB(_, _, _, _, this_enable)
	if not this_enable then
		return
	end
	if UI.UserData["WandDepotCurrentIndex"] == nil then
		UI.UserData["WandDepotCurrentIndex"] = 1
	end
	local CurrentIndex = UI.UserData["WandDepotCurrentIndex"]
	if GetWandDepotSize() == 0 then
		NewWandDepot()
	end
	local CurrentTable = GetWandDepot(CurrentIndex)
	local WandDepotH = 210
	local WandDepotW = 278
	UI.ScrollContainer("WandDepot", 20, 64, WandDepotW, WandDepotH, 2, 2)
	for k, v in pairs(CurrentTable) do
		UI.AddAnywhereItem("WandDepot", function()
			DrawWandSlot("WandDepotSlot", k, v)
		end)
	end
	if #CurrentTable == 0 then
		UI.AddAnywhereItem("WandDepot", function()
			GuiZSetForNextWidget(UI.gui, UI.GetZDeep() - 1)
			GuiText(UI.gui, 5, 5, GameTextGet("$wand_editor_wand_depot_isempty"))
		end)
	end
	UI.AddAnywhereItem("WandDepot", function()

	end)
	UI.DrawScrollContainer("WandDepot", false)
    local DepotSaveCB = function(left_click)
        if left_click then
            ClickSound()
            local held = GetHeldWand()
            if held == nil then
                return
            end
            if #CurrentTable >= TableMax then
                GamePrint(GameTextGet("$wand_editor_wand_depot_limit"))
                return
            end
            local wand = GetWandData(held)
            wand.wandEntity = nil
            CurrentTable[#CurrentTable + 1] = wand
            SetWandDepotLua(CurrentTable, CurrentIndex)
        end
    end
	GuiZSetForNextWidget(UI.gui, UI.GetZDeep())
	UI.MoveImageButton("WandDepotSave", 20, 64 + WandDepotH + 7,
		"mods/wand_editor/files/gui/images/wand_depot_save.png", nil, function()
			GuiTooltip(UI.gui, GameTextGet("$wand_editor_wand_depot_save"), "")
		end, DepotSaveCB, false, true)
    local DepotDeleteCB = function(left_click)
        if left_click then
            ClickSound()
            if UI.UserData["WandDepotKHighlight"] == nil then
                return
            end
            local k = UI.UserData["WandDepotKHighlight"] + 1
            table.remove(CurrentTable, k)
            SetWandDepotLua(CurrentTable, CurrentIndex)
            if k > #CurrentTable then
                UI.UserData["WandDepotKHighlight"] = nil
            end
        end
    end
	GuiZSetForNextWidget(UI.gui, UI.GetZDeep())
	UI.MoveImageButton("WandDepotDelete", 40, 64 + WandDepotH + 7,
		"mods/wand_editor/files/gui/images/wand_depot_delete.png", nil, function()
			GuiTooltip(UI.gui, GameTextGet("$wand_editor_wand_depot_delete"), "")
		end, DepotDeleteCB, false, true)

    local LoadWandCB = function(left_click)
        if left_click then
            ClickSound()
            if UI.UserData["WandDepotKHighlight"] == nil then
                return
            end
            local k = UI.UserData["WandDepotKHighlight"] + 1
            if k <= #CurrentTable then
                local wand = CurrentTable[k]
                InitWand(wand, nil, Compose(EntityGetTransform, GetPlayer)())
            end
        end
    end
	GuiZSetForNextWidget(UI.gui, UI.GetZDeep())
	UI.MoveImageButton("WandDepotLoadWand", 60, 64 + WandDepotH + 7,
		"mods/wand_editor/files/gui/images/wand_depot_loadwand.png", nil, function()
			GuiTooltip(UI.gui, GameTextGet("$wand_editor_wand_depot_loadwand"), "")
		end, LoadWandCB, false, true)

    local RewriteWandCB = function(left_click)
        if left_click then
            ClickSound()
            if UI.UserData["WandDepotKHighlight"] == nil then
                return
            end
            local k = UI.UserData["WandDepotKHighlight"] + 1
            local held = GetHeldWand()
            if held == nil then
                return
            end
            if k <= #CurrentTable then
                local wand = CurrentTable[k]
                InitWand(wand, held)
            end
            UI.OnceCallOnExecute(function()
                RefreshHeldWands()
            end)
        end
    end
	GuiZSetForNextWidget(UI.gui, UI.GetZDeep())
	UI.MoveImageButton("WandDepotRewriteWand", 80, 64 + WandDepotH + 7,
		"mods/wand_editor/files/gui/images/wand_depot_rewritewand.png", nil, function()
			GuiTooltip(UI.gui, GameTextGet("$wand_editor_wand_depot_rewritewand"), "")
		end, RewriteWandCB, false, true)
end

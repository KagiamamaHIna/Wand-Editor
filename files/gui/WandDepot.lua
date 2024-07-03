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

---获得法杖仓库表原始文本
---@param index integer
---@return string
local function GetWandDepotStr(index)
    local size = GetWandDepotSize()
    if index <= size then
        local result = ModSettingGet(ModID .. "WandDepot" .. tostring(index))
        if result == nil then
            return ""
        end
        return result
    end
    error("wand depot index out of bounds:" .. tostring(index))
    return ""
end
local cache
local cacheTable--缓存机制，只有在获取和上个字符串不同的时候才进行读取并检查安全性
---获得法杖仓库表
---@param index integer
---@return table
local function GetWandDepot(index)
	local size = GetWandDepotSize()
    if index <= size then
        local CheckFnStr = tostring(ModSettingGet(ModID .. "WandDepot" .. tostring(index)))
        if cache == nil then--数据缓存
            cache = CheckFnStr
        elseif cache == CheckFnStr and cacheTable then
            return cacheTable
		elseif cache ~= CheckFnStr then
			cache = CheckFnStr
		end
        if HasEnds(CheckFnStr) then
            ModSettingSet(ModID .. "WandDepot" .. tostring(index), "return {}")
            return {}
        end
		local CheckFn = loadstring(CheckFnStr)
		if type(CheckFn) ~= "function" then--数据恢复为空表，有代码或其他行为试图篡改为非法数据
			ModSettingSet(ModID .. "WandDepot" .. tostring(index),"return {}")
			return {}
		end
        local fn = setfenv(CheckFn, {})
        local flag, result = pcall(fn)
        if not flag then --数据恢复为空表，有代码或其他行为试图篡改为非法数据
            ModSettingSet(ModID .. "WandDepot" .. tostring(index), "return {}")
            return {}
        end
		cacheTable = result
		return result
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

---检查数据是否合法
---@param str string
---@return boolean
local function CheckWandDepotData(str)
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
	local baseWand = {
		spells = true, --法术表
		mana_charge_speed = true,      --回蓝速度
		mana_max = true,               --蓝上限
		fire_rate_wait = true,         --施放延迟
		reload_time = true,            --充能延迟
		deck_capacity = true,          --容量
		spread_degrees = true,         --散射
		shuffle_deck_when_empty = true, --是否乱序
		speed_multiplier = true,       --初速度加成
		mana = true,                   --蓝
		actions_per_round = true,      --施放数
		shoot_pos = true, --发射位置
		sprite_file = true,            --贴图
		sprite_pos = true, 	--精灵图偏移
		rect_animation = true
    }
	
	for _,wand in pairs(result)do--判断格式是否正确
		for k,_ in pairs(baseWand)do
            if wand[k] == nil then
				return false
			end
		end
	end
	return true,result
end

---为法杖仓库新建一个页面
---@param t table?
---@return table
local function NewWandDepot(t)
	local index = GetWandDepotSize()
	if index >= 99999 then
		GamePrint(GameTextGet("$wand_editor_wand_depot_wandlist_limit"))
		return {}
	end
	SetWandDepotSize(index + 1)
    index = index + 1
	if t == nil then
		ModSettingSet(ModID .. "WandDepot" .. tostring(index), "return {}")
        return {}
    else
		ModSettingSet(ModID .. "WandDepot" .. tostring(index), "return {\n" .. SerializeTable(t) .. "}")
		return t
	end
end

---删除法杖仓库指定索引页面
---@param index integer
local function RemoveWandDepot(index)
	local max = GetWandDepotSize()
	local key = ModID .. "WandDepot"
    for i = index, max - 1 do
		local newkey = key .. tostring(i + 1)
        local str = ModSettingGet(newkey)
        ModSettingSet(key .. tostring(i), str)
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
	if string.sub(s, #s - 3) == ".xml" then --特殊文件需要处理
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
		local function NewLine(str1, str2)
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
				NewLine("$wand_editor_speed_multiplier", "x" .. string.format("%.8f", wand.speed_multiplier))
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
	local CTRL = InputIsKeyDown(Key_LCTRL) or InputIsKeyDown(Key_RCTRL)
	if left_click and (not CTRL) then
		if UI.UserData["WandDepotKHighlight"] == k then
			UI.UserData["WandDepotKHighlight"] = nil
		else
			UI.UserData["WandDepotKHighlight"] = k
		end
	elseif left_click and CTRL and UI.UserData["WandDepotKHighlight"] then --交换法杖操作
		if k ~= UI.UserData["WandDepotKHighlight"] then
			local CurrentIndex = UI.UserData["WandDepotCurrentIndex"]
            local CurrentTable = GetWandDepot(CurrentIndex)
			if CurrentTable[UI.UserData["WandDepotKHighlight"] + 1] ~= nil and CurrentTable[k + 1] ~= nil then
				local oldTable = CurrentTable[UI.UserData["WandDepotKHighlight"] + 1]
				CurrentTable[UI.UserData["WandDepotKHighlight"] + 1] = wand
				CurrentTable[k + 1] = oldTable
				--TablePrint(CurrentTable)
				--print("k:",k,"|HG:",UI.UserData["WandDepotKHighlight"])
				SetWandDepotLua(CurrentTable, CurrentIndex)
				UI.UserData["WandDepotKHighlight"] = nil
			end
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
        UI.UserData["WandDepotCurrentIndex"] = 1
    end
	local CurrentTable = GetWandDepot(CurrentIndex)
	local WandDepotH = 210
	local WandDepotW = 278
	UI.ScrollContainer("WandDepot", 20, 64, WandDepotW, WandDepotH, 2, 2)
	for k, v in pairs(CurrentTable) do --绘制法杖格
		UI.AddAnywhereItem("WandDepot", function()
			DrawWandSlot("WandDepotSlot", k, v)
		end)
	end
	if #CurrentTable == 0 then --如果是空的绘制一段文本
		UI.AddAnywhereItem("WandDepot", function()
			GuiZSetForNextWidget(UI.gui, UI.GetZDeep() - 1)
			GuiText(UI.gui, 5, 5, GameTextGet("$wand_editor_wand_depot_isempty"))
		end)
	end
	UI.AddAnywhereItem("WandDepot", function()
		GuiLayoutBeginHorizontal(UI.gui, 2, WandDepotH - 10, true)
		GuiZSetForNextWidget(UI.gui, UI.GetZDeep() - 1)
		local add_click = GuiButton(UI.gui, UI.NewID("WandDepotAddTable"), 0, 0, "[+]") --新增页面按钮
        GuiTooltip(UI.gui, GameTextGet("$wand_editor_wand_depot_newpage"), "")
		local CTRL = InputIsKeyDown(Key_LCTRL) or InputIsKeyDown(Key_RCTRL)
        if add_click and CTRL then
            local ClipboardData = Cpp.GetClipboard()
			local flag,newPage = CheckWandDepotData(ClipboardData)
			if flag then
                NewWandDepot(newPage)
				GamePrint(GameTextGet("$wand_editor_wand_depot_copy_correctly"))
            else
				GamePrint(GameTextGet("$wand_editor_wand_depot_copy_error"))
			end
		elseif add_click then
			NewWandDepot()
		end

		GuiZSetForNextWidget(UI.gui, UI.GetZDeep() - 1)
		local delete_click = GuiButton(UI.gui, UI.NewID("WandDepotDeleteTable"), 11, 0, "[x]") --删除页面按钮
		local deleteTextKey = "$wand_editor_wand_depot_deletepage"
		if UI.UserData["wand_depot_IKnowWhatImDoing"] then
			deleteTextKey = "$wand_editor_wand_depot_deletepage_IKnowWhatImDoing"
		end
		GuiTooltip(UI.gui, GameTextGet(deleteTextKey), "")
		local _, _, delete_hover = GuiGetPreviousWidgetInfo(UI.gui)
        if UI.UserData["wand_depot_IKnowWhatImDoing"] and delete_hover and delete_click then
            UI.UserData["wand_depot_IKnowWhatImDoing"] = false
            if CurrentIndex > GetWandDepotSize() - 1 and CurrentIndex - 1 ~= 0 then --防止越界
                UI.UserData["WandDepotCurrentIndex"] = CurrentIndex - 1
            end
            RemoveWandDepot(CurrentIndex)
        elseif UI.UserData["wand_depot_IKnowWhatImDoing"] and (not delete_hover) then
            UI.UserData["wand_depot_IKnowWhatImDoing"] = false
        elseif delete_click and delete_hover then
            UI.UserData["wand_depot_IKnowWhatImDoing"] = true
        end
		
		GuiZSetForNextWidget(UI.gui, UI.GetZDeep() - 1)
        local CopyDepot_click = GuiButton(UI.gui, UI.NewID("WandDepotCopyDepot"), 12, 0, "[c]")
		GuiTooltip(UI.gui, GameTextGet("$wand_editor_wand_depot_copy"), "")
        if CopyDepot_click then
			Cpp.SetClipboard(GetWandDepotStr(CurrentIndex))
		end
		GuiLayoutEnd(UI.gui)

		GuiLayoutBeginHorizontal(UI.gui, WandDepotW / 2 - 47, WandDepotH - 10, true)
		GuiZSetForNextWidget(UI.gui, UI.GetZDeep() - 1)
		local topmast_click = GuiButton(UI.gui, UI.NewID("WandDepotTopmost"), 0, 0, "<<")
		if topmast_click then
			UI.UserData["WandDepotCurrentIndex"] = 1
		end
		GuiZSetForNextWidget(UI.gui, UI.GetZDeep() - 1)
		local up_click = GuiButton(UI.gui, UI.NewID("WandDepotUp"), 5, 0, "<")
		if up_click and CurrentIndex > 1 then
			UI.UserData["WandDepotCurrentIndex"] = UI.UserData["WandDepotCurrentIndex"] - 1
		end
		GuiLayoutEnd(UI.gui)

		GuiLayoutBeginHorizontal(UI.gui, WandDepotW / 2, WandDepotH - 10, true)

		GuiOptionsAddForNextWidget(UI.gui, GUI_OPTION.Align_HorizontalCenter)
		GuiZSetForNextWidget(UI.gui, UI.GetZDeep() - 1)
		local text = UI.TextInput("WandDepotPage", 0, 0, 35, 5, "1", "1234567890")
		local _, _, hover = GuiGetPreviousWidgetInfo(UI.gui)
		local page = tonumber(text)
		if not hover and text == "" then
			UI.TextInputRestore("WandDepotPage")
		elseif page and page ~= CurrentIndex and hover then
			if page > GetWandDepotSize() then
				local max = GetWandDepotSize()
				UI.UserData["WandDepotCurrentIndex"] = max
				UI.SetInputText("WandDepotPage", tostring(max))
			else --及时同步
				UI.UserData["WandDepotCurrentIndex"] = page
			end
		elseif page and page ~= CurrentIndex then
			UI.SetInputText("WandDepotPage", tostring(CurrentIndex))
		end
		GuiZSetForNextWidget(UI.gui, UI.GetZDeep() - 1)
		GuiText(UI.gui, -4, 0, "/" .. tostring(math.max(GetWandDepotSize(), 1)))

		GuiZSetForNextWidget(UI.gui, UI.GetZDeep() - 1)
		local next_click = GuiButton(UI.gui, UI.NewID("WandDepotNext"), 2, 0, ">")
		if next_click and CurrentIndex < GetWandDepotSize() then
			UI.UserData["WandDepotCurrentIndex"] = CurrentIndex + 1
		end
		GuiZSetForNextWidget(UI.gui, UI.GetZDeep() - 1)
		local bottom_click = GuiButton(UI.gui, UI.NewID("WandDepotBottom"), 7, 0, ">>")
		if bottom_click then
			UI.UserData["WandDepotCurrentIndex"] = GetWandDepotSize()
		end
		GuiLayoutEnd(UI.gui)
	end)
	UI.DrawScrollContainer("WandDepot", false) --绘制框内控件和框
		
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
            if UI.UserData["wand_depot_deleteWand_IKnowWhatImDoing"] == nil then
                UI.UserData["wand_depot_deleteWand_IKnowWhatImDoing"] = true
                return
            end
			UI.UserData["wand_depot_deleteWand_IKnowWhatImDoing"] = nil
            local k = UI.UserData["WandDepotKHighlight"] + 1
            table.remove(CurrentTable, k)
            SetWandDepotLua(CurrentTable, CurrentIndex)
            if k > #CurrentTable then
                UI.UserData["WandDepotKHighlight"] = nil
            end
        end
    end
    local deleteTextKey = "$wand_editor_wand_depot_delete"
	if UI.UserData["wand_depot_deleteWand_IKnowWhatImDoing"] then
		deleteTextKey = "$wand_editor_wand_depot_delete_IKnowWhatImDoing"
	end
	GuiZSetForNextWidget(UI.gui, UI.GetZDeep())
	UI.MoveImageButton("WandDepotDelete", 45, 64 + WandDepotH + 7,
        "mods/wand_editor/files/gui/images/wand_depot_delete.png", nil, function()
            local _, _, hover = GuiGetPreviousWidgetInfo(UI.gui)
			if not hover then
				UI.UserData["wand_depot_deleteWand_IKnowWhatImDoing"] = nil
			end
			GuiTooltip(UI.gui, GameTextGet(deleteTextKey), "")
		end, DepotDeleteCB, false, true)

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
	UI.MoveImageButton("WandDepotRewriteWand", 70, 64 + WandDepotH + 7,
		"mods/wand_editor/files/gui/images/wand_depot_rewritewand.png", nil, function()
			GuiTooltip(UI.gui, GameTextGet("$wand_editor_wand_depot_rewritewand"), "")
		end, RewriteWandCB, false, true)

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
	UI.MoveImageButton("WandDepotLoadWand", 95, 64 + WandDepotH + 7,
		"mods/wand_editor/files/gui/images/wand_depot_loadwand.png", nil, function()
			GuiTooltip(UI.gui, GameTextGet("$wand_editor_wand_depot_loadwand"), "")
        end, LoadWandCB, false, true)
		
    local function HelpHover()
        UI.tooltips(function()
            GuiText(UI.gui, 0, 0, GameTextGetTranslatedOrNot("$wand_editor_wand_depot_help"))
        end, nil, 5)
    end
	GuiZSetForNextWidget(UI.gui, UI.GetZDeep())
	UI.MoveImageButton("WandDepotHelp", 130,64 + WandDepotH + 11,
		"mods/wand_editor/files/gui/images/help.png", nil, HelpHover, nil, nil, true)
end

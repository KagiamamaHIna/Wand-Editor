dofile_once("data/scripts/gun/procedural/gun_procedural.lua")
local this = UI
local sliderModeKey = ModID .. "sliderMode"
local sliderMode = ModSettingGet(sliderModeKey)
if sliderMode == nil then
    ModSettingSet(sliderModeKey, false)
	sliderMode = false
end
local function GetValue(id, isDecimal)
    local num
	if sliderMode then
		num = UI.GetSliderValue(id.."WBSlider")
    else
		num = tonumber(UI.GetInputText(id))
	end
    if num == nil then
        return ""
    end
    if isDecimal then
        return num
    end
    return math.floor(num)
end

local function GetValueSToF(id, isDecimal)
    local num
	if sliderMode then
		num = UI.GetSliderValue(id.."WBSlider")
    else
		num = tonumber(UI.GetInputText(id) or "")
	end
    if num == nil then
        return ""
    end
	if not sliderMode then
		num = math.floor(num*60 + 0.5)
	end
    if isDecimal then
        return num
    end
    return math.floor(num)
end

---通过设置参数获得一根新法杖
---@return Wand
local function GetWand()
	local shuffleBool = UI.GetCheckboxEnable("shuffle_builder")
	local IsShuffle
    if shuffleBool then
        IsShuffle = 1
    else
        IsShuffle = 0
    end
    local GetDeckCapacity = Compose(tonumber, UI.GetInputText)
	if sliderMode then
		GetDeckCapacity = function (str)
			return math.floor(UI.GetSliderValue(str.."WBSlider"))
		end
	end
	local NewWand = {
		item_name = nil,
		mana_charge_speed = GetValue("manachargespeed_builder"),      					--回蓝速度
		mana_max = GetValue("manamax_builder"),               							--蓝上限
		fire_rate_wait = GetValueSToF("castdelay_builder"),         					--施放延迟
		reload_time = GetValueSToF("rechargetime_builder"),            					--充能延迟
		deck_capacity = GetDeckCapacity("capacity_builder"),          					--容量
		spread_degrees = GetValue("spread_builder",true),         						--散射
		shuffle_deck_when_empty = IsShuffle, 											--是否乱序
		speed_multiplier = GetValue("speed_multiplier_builder", true),       			--初速度加成
		mana = GetValue("manamax_builder"),                   							--蓝
		actions_per_round = GetValue("cast_builder"),      								--施放数
		shoot_pos = { x = 0, y = 0 }, 													--发射位置
		sprite_file = nil,            													--贴图
		sprite_pos = { x = 0, y = 0 } 													--精灵图偏移
    }
    SetRandomSeed(Compose(EntityGetTransform, GetPlayer)())
	--这里是改的原版生成贴图的代码
	local gun_in_wand_space = {}
	gun_in_wand_space.fire_rate_wait = clamp(((NewWand["fire_rate_wait"] + 5) / 7)-1, 0, 4)
	gun_in_wand_space.actions_per_round = clamp(NewWand["actions_per_round"]-1,0,2)
	gun_in_wand_space.shuffle_deck_when_empty = clamp(NewWand["shuffle_deck_when_empty"], 0, 1)
	gun_in_wand_space.deck_capacity = clamp( (NewWand["deck_capacity"]-3)/3, 0, 7 ) -- TODO
	gun_in_wand_space.spread_degrees = clamp( ((NewWand["spread_degrees"] + 5 ) / 5 ) - 1, 0, 2 )
	gun_in_wand_space.reload_time = clamp(((NewWand["reload_time"] + 5) / 25) - 1, 0, 2)
	
	local best_wand = nil
	local best_score = 1000
	for k, wand in pairs(wands) do
		local score = WandDiff(gun_in_wand_space, wand)
		if (score <= best_score) then
			best_wand = wand
			best_score = score
			-- just randomly return one of them...
			if (score == 0 and Random(0, 100) < 33) then
				best_wand = wand
				break
			end
		end
	end
	NewWand.shuffle_deck_when_empty = shuffleBool
	NewWand.sprite_pos.x = best_wand.grip_x
	NewWand.sprite_pos.y = best_wand.grip_y
	NewWand.shoot_pos.x = best_wand.tip_x - best_wand.grip_x
	NewWand.shoot_pos.y = best_wand.tip_y - best_wand.grip_y
    NewWand.sprite_file = best_wand.file
	return NewWand
end

local function NewSlider(id,x,y,text,value_min, value_max, value_default, value_display_multiplier, value_formatting, width)
	id = id.."WBSlider"
    UI.Slider(id, x, y, text, value_min, value_max, value_default, value_display_multiplier, value_formatting, width)
    local _, _, hover= GuiGetPreviousWidgetInfo(UI.gui)
	local XOffset = UI.UserData["WandBuilderXOffset"] or 0
	GuiTooltip(this.gui,GameTextGet("$menuoptions_reset_keyboard").."\n"..GameTextGet("$wand_editor_wand_builder_slider_tips"),"",XOffset+2)

    local function MoveSlider()
        local left = InputIsKeyDown(Key_KP_MINUS) or InputIsKeyDown(Key_LEFT) or InputIsKeyDown(Key_MINUS)
        local right = InputIsKeyDown(Key_KP_PLUS) or InputIsKeyDown(Key_RIGHT) or InputIsKeyDown(Key_EQUALS)
        local num = 1
        if InputIsKeyDown(Key_LSHIFT) or InputIsKeyDown(Key_RSHIFT) then --按下shift一次移动更多
            num = num * 10
        end
        if left then
            UI.SetSliderValue(id, UI.GetSliderValue(id) - num)
        elseif right then
            UI.SetSliderValue(id, UI.GetSliderValue(id) + num)
        end
    end
    if hover then
        local hasPush = InputIsKeyDown(Key_KP_PLUS) or InputIsKeyDown(Key_KP_MINUS) or InputIsKeyDown(Key_LEFT) or
            InputIsKeyDown(Key_RIGHT) or InputIsKeyDown(Key_MINUS) or InputIsKeyDown(Key_EQUALS)
        if UI.UserData["PushFrBuilderID" .. id] == nil then --如果在悬浮，就分配一个帧检测时间
            UI.UserData["PushFrBuilderID" .. id] = 30
        else
            if hasPush then                                        --如果按了
                if UI.UserData["PushFrBuilderID" .. id] == 30 then --按的第一下
                    MoveSlider()
                end
                if UI.UserData["PushFrBuilderID" .. id] ~= 0 then
                    UI.UserData["PushFrBuilderID" .. id] = UI.UserData["PushFrBuilderID" .. id] - 1
                else --如果到了0
                    MoveSlider()
                end
            else
                UI.UserData["PushFrBuilderID" .. id] = 30 --如果不按就重置时间
            end
        end
    elseif UI.UserData["PushFrBuilderID" .. id] then --如果未悬浮就设为空
        UI.UserData["PushFrBuilderID" .. id] = nil
    end
	return width,hover
end

local function NumInput(id, x, y, w, l, str, allow)
	l = -1--不管显示会不会超出了，直接自动分配可输入字符
	allow = Default(allow, "1234567890.-")
    UI.TextInput(id, x, y, w, l, str, allow)
    local _,right_click, hover,_,_,width = GuiGetPreviousWidgetInfo(UI.gui)
    if not hover then --文本检查
        local srcText = UI.GetInputText(id)
        local text = tonumber(srcText)
        if text == nil then
            UI.TextInputRestore(id)
        elseif text ~= nil then
            local Format = tostring(text)
            if Format ~= srcText then
                UI.SetInputText(id, Format)
            end
        end
    end
    GuiTooltip(UI.gui, GameTextGetTranslatedOrNot("$menuoptions_reset_keyboard"), "",UI.UserData["WandBuilderXOffset"])
    if right_click then
        UI.TextInputRestore(id)
        GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", GameGetCameraPos())
    end
	return width,hover
end

function WandBuilderCB(_, _, _, _, this_enable)
    if not this_enable then
        return
    end
	UI.ScrollContainer("WandBuilder", 20, 64, 268, 160, 2, 2)
	UI.AddAnywhereItem("WandBuilder", function()
        local function GetValueStr(id, format)
            local num
			if sliderMode then
				num = UI.GetSliderValue(id.."WBSlider")
			else
				num = UI.GetInputText(id)
			end
            if num == nil or tonumber(num) == nil or num == "" then
                return ""
            end
            if format then
                return string.format(format, tonumber(num))
            end
            return Compose(tostring, math.floor)(num)
        end
        local function GetValueStrSToF(id, format)
            local num
			if sliderMode then
				num = tonumber(UI.GetSliderValue(id.."WBSlider") or "")
			else
                num = tonumber(UI.GetInputText(id) or "")
			end
            if num == nil then
                return ""
            end
			if not sliderMode then
				num = math.floor(num*60 + 0.5)
			end
			if format then
                return string.format(format, num)
			end
			return Compose(tostring, math.floor)(num)
		end
		local leftMargin = 65
        local ColTwoMargin = 73
		if sliderMode then
			ColTwoMargin = 103
		end
		local function NewLine(str, ShowText, fn, ShowFrTran)
			str = GameTextGetTranslatedOrNot(str)
			GuiLayoutBeginHorizontal(this.gui, 0, 0, true, 0, 2)
			local w = GuiGetTextDimensions(this.gui, str)
			GuiZSetForNextWidget(this.gui, this.GetZDeep() - 1)
            GuiText(this.gui, leftMargin - w, 0, str)
			if ShowText == "" or ShowText == nil then
                ShowText = " "
			elseif ShowFrTran then
				local num = tonumber(ShowText)
				local SecondWithSign = Compose(NumToWithSignStr, tonumber, FrToSecondStr)
				if num then
					ShowText = SecondWithSign(num) .. "s(" .. ShowText .. "f)"
				end
			end

			GuiZSetForNextWidget(this.gui, this.GetZDeep() - 1)
            local wdith,hover = fn(3)
			GuiZSetForNextWidget(this.gui, this.GetZDeep() - 1)
            GuiRGBAColorSetForNextWidget(this.gui, 255, 222, 173, 255)
			if hover then
				local textW = GuiGetTextDimensions(this.gui,ShowText)
				UI.UserData["WandBuilderXOffset"] = textW
			end
			GuiText(this.gui, ColTwoMargin-wdith, 0, ShowText)
			GuiLayoutEnd(this.gui)
		end
        GuiLayoutBeginVertical(this.gui, 0, 0, true)
		local shuffle
		if UI.GetCheckboxEnable("shuffle_builder") then
			shuffle = GameTextGet("$menu_yes")
		else
			shuffle = GameTextGet("$menu_no")
		end
		NewLine("$inventory_shuffle", shuffle, function(ShowW)
            UI.checkbox("shuffle_builder", ShowW + 2, 1, "", nil, nil, nil, nil)
			if sliderMode then
				return 25,false
            else
				return 24.5,false
			end
		end)
		NewLine("$inventory_actionspercast", GetValueStr("cast_builder"), function(ShowW)
			if sliderMode then
            	return NewSlider("cast_builder", ShowW, 1, "", 1, 50, 1, 1, " ", 100)
            else
				return NumInput("cast_builder", ShowW + 2, 1, 70, 9, "1", "1234567890")
			end
		end)
        NewLine("$inventory_castdelay", GetValueStrSToF("castdelay_builder"), function(ShowW)
			if sliderMode then
            	return NewSlider("castdelay_builder", ShowW, 1, "", -21, 240, 10, 1, " ", 100)
			else
				return NumInput("castdelay_builder", ShowW + 2, 1, 70, 7, "0.17", "1234567890.-")
			end
		end, true)
        NewLine("$inventory_rechargetime", GetValueStrSToF("rechargetime_builder"), function(ShowW)
			if sliderMode then
            	return NewSlider("rechargetime_builder", ShowW, 1, "", -21, 240, 20, 1, " ", 100)
			else
	            return NumInput("rechargetime_builder", ShowW + 2, 1, 70, 7, "0.33", "1234567890.-")
			end
		end, true)
        NewLine("$inventory_manamax", GetValueStr("manamax_builder"), function(ShowW)
			if sliderMode then
            	return NewSlider("manamax_builder", ShowW, 1, "", 0, 20000, 2000, 1, " ", 100)
			else
				return NumInput("manamax_builder",ShowW + 2, 1, 70,9,"2000","1234567890")
			end
		end)
        NewLine("$inventory_manachargespeed", GetValueStr("manachargespeed_builder"), function(ShowW)
			if sliderMode then
            	return NewSlider("manachargespeed_builder", ShowW, 1, "", 0, 20000, 500, 1, " ", 100)
			else
				return NumInput("manachargespeed_builder",ShowW + 2, 1, 70,9,"500","1234567890")
			end
		end)
        NewLine("$inventory_capacity", GetValueStr("capacity_builder"), function(ShowW)
			if sliderMode then
				return NewSlider("capacity_builder", ShowW, 1, "", 1, 50, 26, 1, " ", 100)
			else
				return NumInput("capacity_builder", ShowW + 2, 0, 70, 9, "26", "1234567890")
			end
		end)
        NewLine("$inventory_spread", GetValueStr("spread_builder") .. GameTextGet("$wand_editor_deg"), function(ShowW)
			if sliderMode then
				return NewSlider("spread_builder", ShowW, 1, "", -30, 30, 0, 1," ",100)
			else
				return NumInput("spread_builder", ShowW + 2, 0, 70, 9, "0", "1234567890.-")
			end
        end)
        NewLine("$wand_editor_speed_multiplier", "x" .. GetValueStr("speed_multiplier_builder", "%.8f"), function(ShowW)
			if sliderMode then
			    return NewSlider("speed_multiplier_builder", ShowW, 1, "", 0, 2, 1, 0.0001, " ", 100)
			else
				return NumInput("speed_multiplier_builder", ShowW + 2, 0, 70, 10, "1", "1234567890.-")
			end
			--GuiTooltip(this.gui,GameTextGetTranslatedOrNot("$menuoptions_reset_keyboard"),"")
        end)
		local UpdateImage
		if UI.GetCheckboxEnable("update_image_builder") then
			UpdateImage = GameTextGet("$menu_yes")
		else
			UpdateImage = GameTextGet("$menu_no")
		end
		NewLine("$wand_editor_update_wand_image", UpdateImage, function(ShowW)
            UI.checkbox("update_image_builder", ShowW + 2, 1, "", nil, nil, nil, nil)
			if sliderMode then
				return 25,false
            else
				return 24.5,false
			end
		end)
		
		GuiLayoutAddVerticalSpacing(this.gui, 18)
        GuiLayoutBeginHorizontal(this.gui, 0, 0, true, 4, 2)
        GuiZSetForNextWidget(this.gui, this.GetZDeep()-1)
        if GuiButton(this.gui, this.NewID("wand_builder_botton"), 4, 0, GameTextGet("$wand_editor_wand_builder_botton")) then
			InitWand(GetWand(),nil,Compose(EntityGetTransform, GetPlayer)())
		end
		GuiZSetForNextWidget(this.gui, this.GetZDeep()-1)
		local click = GuiButton(this.gui, this.NewID("wand_builder_held_botton"), 4, 0, GameTextGet("$wand_editor_wand_builder_held_botton"))
		GuiTooltip(this.gui,GameTextGet("$wand_editor_wand_builder_held_botton_tip"),"")
        if click then
            local wand = Compose(GetEntityHeldWand, GetPlayer)()
			if wand ~= nil then
                local wandData = GetWandData(wand)
				if InputIsKeyDown(Key_LSHIFT) or InputIsKeyDown(Key_RSHIFT) then
                    this.SetCheckboxEnable("shuffle_builder", wandData.shuffle_deck_when_empty)
					if sliderMode then
						local SetSlider = function (id, v)
							this.SetSliderValue(id.."WBSlider", v)
						end
						SetSlider("cast_builder", wandData.actions_per_round)
						SetSlider("castdelay_builder", wandData.fire_rate_wait)
						SetSlider("rechargetime_builder", wandData.reload_time)
						SetSlider("manamax_builder", wandData.mana_max)
						SetSlider("manachargespeed_builder", wandData.mana_charge_speed)
						SetSlider("capacity_builder", wandData.deck_capacity)
						SetSlider("spread_builder", wandData.spread_degrees)
						SetSlider("speed_multiplier_builder", wandData.speed_multiplier)
                    else
						this.SetInputText("cast_builder", wandData.actions_per_round)
						this.SetInputText("castdelay_builder", FrToSecondStr(wandData.fire_rate_wait))
						this.SetInputText("rechargetime_builder", FrToSecondStr(wandData.reload_time))
						this.SetInputText("manamax_builder", wandData.mana_max)
						this.SetInputText("manachargespeed_builder", wandData.mana_charge_speed)
						this.SetInputText("capacity_builder", tostring(wandData.deck_capacity))
						this.SetInputText("spread_builder", wandData.spread_degrees)
						this.SetInputText("speed_multiplier_builder", wandData.speed_multiplier)
					end
                else
					InitWand(wandData,nil,Compose(EntityGetTransform, GetPlayer)())
				end
			end
		end
		GuiZSetForNextWidget(this.gui, this.GetZDeep()-1)
        if GuiButton(this.gui, this.NewID("wand_builder_update_botton"), 4, 0, GameTextGet("$wand_editor_wand_builder_update_botton")) then
            local wand = Compose(GetEntityHeldWand, GetPlayer)()
            if wand ~= nil then
                local wandData = GetWandData(wand)
                local new = GetWand()
                for i = new.deck_capacity + 1, #wandData.spells.spells do --删除越界法术
                    wandData.spells.spells[i] = nil
                end
                new.spells = wandData.spells --更新法杖的时候不要更新法术啥的
                if this.GetCheckboxEnable("update_image_builder") then
                    InitWand(new, wand)
                else
                    new.sprite_file = wandData.sprite_file
                    new.shoot_pos = wandData.shoot_pos
                    new.sprite_pos = wandData.sprite_pos
                    new.spells = wandData.spells
                    InitWand(new, wand)
                end
                this.OnceCallOnExecute(function()
                    RefreshHeldWands()
                end)
            end
        end
        GuiZSetForNextWidget(this.gui, this.GetZDeep() - 1)
        local modeStr
		local modeTipsStr
		if sliderMode then
            modeStr = GameTextGet("$wand_editor_wand_builder_slider_mode")
            modeTipsStr = GameTextGet("$wand_editor_wand_builder_slider_mode_tips")
        else
            modeStr = GameTextGet("$wand_editor_wand_builder_input_box_mode")
			modeTipsStr = GameTextGet("$wand_editor_wand_builder_input_box_mode_tips")
		end
        local modeSwtich = GuiButton(this.gui, this.NewID("wand_builder_update_switch"), 4, 0, modeStr)
        GuiTooltip(this.gui, modeTipsStr)
		if modeSwtich then
            sliderMode = not sliderMode
			ModSettingSet(sliderModeKey, sliderMode)
		end
        GuiLayoutEnd(this.gui)
        GuiLayoutEnd(this.gui)
	end)
    UI.DrawScrollContainer("WandBuilder", false, true)
	
    local flag, wand = pcall(GetWand)
    if flag then
        local w, h = GuiGetImageDimensions(UI.gui, wand.sprite_file, 3)
		GuiZSetForNextWidget(UI.gui,UI.GetZDeep())
		GuiImage(UI.gui,UI.NewID("wand_build_preview_images"),20,UI.GetScrollHeight("WandBuilder") + UI.GetScrollY("WandBuilder") + 5,wand.sprite_file,1,3,0)
	end
end

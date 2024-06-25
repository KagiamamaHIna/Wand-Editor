dofile_once("data/scripts/gun/procedural/gun_procedural.lua")
local this = UI
local function GetValue(id, isDecimal)
    local num = UI.GetSliderValue(id)
    if num == nil then
        return ""
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
	local NewWand = {
		item_name = nil,
		mana_charge_speed = GetValue("manachargespeed_builder"),      --回蓝速度
		mana_max = GetValue("manamax_builder"),               --蓝上限
		fire_rate_wait = GetValue("castdelay_builder"),         --施放延迟
		reload_time = GetValue("rechargetime_builder"),            --充能延迟
		deck_capacity = Compose(tonumber,UI.GetInputText)("capacity_builder"),          --容量
		spread_degrees = GetValue("spread_builder"),         --散射
		shuffle_deck_when_empty = IsShuffle, --是否乱序
		speed_multiplier = GetValue("speed_multiplier_builder", true),       --初速度加成
		mana = GetValue("manamax_builder"),                   --蓝
		actions_per_round = GetValue("cast_builder"),      --施放数
		shoot_pos = { x = 0, y = 0 }, --发射位置
		sprite_file = nil,            --贴图
		sprite_pos = { x = 0, y = 0 } --精灵图偏移
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

function WandBuilderCB(_, _, _, _, this_enable)
	if not this_enable then
		return
	end
	local BuilderH = 160
	UI.ScrollContainer("WandBuilder", 20, 64, 268, BuilderH, 2, 2)
	UI.AddAnywhereItem("WandBuilder", function()
		local function GetValueStr(id, format)
			local num = UI.GetSliderValue(id)
            if num == nil then
                return ""
            end
			if format then
                return string.format(format, tonumber(num))
			end
			return Compose(tostring, math.floor)(num)
		end
		local leftMargin = 65
		local ColTwoMargin = 68
		local function NewLine(str, ShowText, fn, NoTip, ShowFrTran)
			str = GameTextGetTranslatedOrNot(str)
			GuiLayoutBeginHorizontal(this.gui, 0, 0, true, 0, 2)
			local w = GuiGetTextDimensions(this.gui, str)
			GuiZSetForNextWidget(this.gui, this.GetZDeep() - 1)
			GuiText(this.gui, leftMargin - w, 0, str)
			if ShowFrTran then
				local num = tonumber(ShowText)
				local SecondWithSign = Compose(NumToWithSignStr, tonumber, FrToSecondStr)
				if num then
					ShowText = SecondWithSign(num) .. "s(" .. ShowText .. "f)"
				end
			end
			if ShowText == "" or ShowText == nil then
				ShowText = " "
			end
			local ShowW = GuiGetTextDimensions(this.gui, ShowText)
			ShowW = GuiGetTextDimensions(this.gui, ShowText)
			GuiRGBAColorSetForNextWidget(this.gui, 255,222,173, 255)
			GuiZSetForNextWidget(this.gui, this.GetZDeep() - 1)
			GuiText(this.gui, 5, 0, ShowText)
			GuiZSetForNextWidget(this.gui, this.GetZDeep() - 1)
            fn(ColTwoMargin - ShowW)
			if not NoTip then
				GuiTooltip(this.gui,GameTextGetTranslatedOrNot("$menuoptions_reset_keyboard"),"")
			end
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
			UI.checkbox("shuffle_builder", ShowW+2, 1, "", nil, nil, nil, nil)
		end, true)
		NewLine("$inventory_actionspercast", GetValueStr("cast_builder"), function(ShowW)
			UI.Slider("cast_builder", ShowW, 1, "", 1, 50, 1, 1," ",120)
		end)
		NewLine("$inventory_castdelay", GetValueStr("castdelay_builder"), function(ShowW)
			UI.Slider("castdelay_builder", ShowW, 1, "", -21, 240, 10, 1," ",120)
		end,false, true)
		NewLine("$inventory_rechargetime", GetValueStr("rechargetime_builder"), function(ShowW)
			UI.Slider("rechargetime_builder", ShowW, 1, "", -21, 240, 20, 1," ",120)
		end,false, true)
		NewLine("$inventory_manamax", GetValueStr("manamax_builder"), function(ShowW)
			UI.Slider("manamax_builder", ShowW, 1, "", 0, 20000, 2000, 1," ",120)
		end)
		NewLine("$inventory_manachargespeed", GetValueStr("manachargespeed_builder"), function(ShowW)
			UI.Slider("manachargespeed_builder", ShowW, 1, "", 0, 20000, 500, 1," ",120)
		end)
		NewLine("$inventory_capacity", UI.GetInputText("capacity_builder"), function(ShowW)
            UI.TextInput("capacity_builder", ShowW + 2, 0, 120, 9, "26", "1234567890")
            local str = UI.GetInputText("capacity_builder")
			if str ~= "" then
                local num = tonumber(str)
				if num > 500 then
					UI.SetInputText("capacity_builder", "500")
				end
			end
            local _, _, hover = GuiGetPreviousWidgetInfo(this.gui)
			if not hover and UI.GetInputText("capacity_builder") == "" or (hover and InputIsMouseButtonDown(Mouse_right)) then
				UI.TextInputRestore("capacity_builder")
			end
		end)
		NewLine("$inventory_spread", GetValueStr("spread_builder")..GameTextGet("$wand_editor_deg"), function(ShowW)
			UI.Slider("spread_builder", ShowW, 1, "", -30, 30, 0, 1," ",120)
        end)
		NewLine("$wand_editor_speed_multiplier", "x"..GetValueStr("speed_multiplier_builder", "%.4f"), function(ShowW)
			UI.Slider("speed_multiplier_builder", ShowW, 1, "", 0, 2, 1, 0.0001," ",120)
        end)
		local UpdateImage
		if UI.GetCheckboxEnable("update_image_builder") then
			UpdateImage = GameTextGet("$menu_yes")
		else
			UpdateImage = GameTextGet("$menu_no")
		end
		NewLine("$wand_editor_update_wand_image", UpdateImage, function(ShowW)
			UI.checkbox("update_image_builder", ShowW+2, 1, "", nil, nil, nil, nil)
		end, true)
        GuiLayoutEnd(this.gui)
        GuiLayoutBeginHorizontal(this.gui, 0, BuilderH-12, true, 4, 2)
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
					this.SetSliderValue("cast_builder", wandData.actions_per_round)
					this.SetSliderValue("castdelay_builder", wandData.fire_rate_wait)
					this.SetSliderValue("rechargetime_builder", wandData.reload_time)
					this.SetSliderValue("manamax_builder", wandData.mana_max)
					this.SetSliderValue("manachargespeed_builder", wandData.mana_charge_speed)
					this.SetInputText("capacity_builder", tostring(wandData.deck_capacity))
					this.SetSliderValue("spread_builder", wandData.spread_degrees)
                    this.SetSliderValue("speed_multiplier_builder", wandData.speed_multiplier)
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
				new.spells = wandData.spells
                if this.GetCheckboxEnable("update_image_builder") then
                    InitWand(new, wand)
                else
                    new.sprite_file = wandData.sprite_file
                    new.shoot_pos = wandData.shoot_pos
                    new.sprite_pos = wandData.sprite_pos
					new.spells = wandData.spells
                    InitWand(new, wand)
                end
				this.OnceCallOnExecute(function ()
					RefreshHeldWands()
				end)
			end
		end
		GuiLayoutEnd(this.gui)
	end)
	UI.DrawScrollContainer("WandBuilder", false)
end

dofile_once("mods/wand_editor/files/libs/fn.lua")

local function NumInput(id, x, y, w, l, str)
    UI.TextInput(id, x, y, w, l, str, "1234567890.-")
    local _,right_click, hover = GuiGetPreviousWidgetInfo(UI.gui)
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
    GuiTooltip(UI.gui, GameTextGetTranslatedOrNot("$menuoptions_reset_keyboard"), "")
	if right_click then
		UI.TextInputRestore(id)
	end
end

local leftMargin = 65
local ColTwoMargin = 87

local function NewDamageSettingLine(str, id)
    str = GameTextGetTranslatedOrNot(str)
	
	GuiLayoutBeginHorizontal(UI.gui, 0, 0, true, 0, 2)
    local w = GuiGetTextDimensions(UI.gui, str)
	GuiZSetForNextWidget(UI.gui, UI.GetZDeep())
    GuiText(UI.gui, leftMargin - w, 0, str)
    local ShowText = UI.GetInputText(id)
	
    if ShowText == "" or ShowText == nil then
        ShowText = " "
    else
        ShowText = "x" .. ShowText
    end
	
	local ShowW = GuiGetTextDimensions(UI.gui, ShowText)
	ShowW = GuiGetTextDimensions(UI.gui, ShowText)
    GuiRGBAColorSetForNextWidget(UI.gui, 255, 222, 173, 255)
	
	GuiZSetForNextWidget(UI.gui, UI.GetZDeep())
	GuiText(UI.gui, 5, 0, ShowText)
	
    GuiZSetForNextWidget(UI.gui, UI.GetZDeep())
    NumInput(id, ColTwoMargin - ShowW, 0, 90, 14, "1")
	
	GuiLayoutEnd(UI.gui)
end

local function GetDmgNum(id)
	return tonumber(UI.GetInputText(id)) or 0
end

function SpwanDummyCB(_, _, _, _, this_enable)
    if not this_enable then
        return
    end
	local ContainerH = 210
    UI.ScrollContainer("SpwanDummyOptions", 20, 64, 268, ContainerH, 2, 2)
    UI.AddAnywhereItem("SpwanDummyOptions", function()
        GuiLayoutBeginVertical(UI.gui, 0, 0, true)
        NewDamageSettingLine("$wand_editor_dmg_proj", "DummyDmgProj")
        NewDamageSettingLine("$wand_editor_dmg_expl", "DummyDmgExpl")
        NewDamageSettingLine("$wand_editor_dmg_electric", "DummyDmgElectric")
        NewDamageSettingLine("$wand_editor_dmg_slice", "DummyDmgSlice")
		NewDamageSettingLine("$wand_editor_dmg_drill", "DummyDmgDrill")
		NewDamageSettingLine("$wand_editor_dmg_fire", "DummyDmgFire")
		NewDamageSettingLine("$wand_editor_dmg_ice", "DummyDmgIce")
        NewDamageSettingLine("$wand_editor_dmg_melee", "DummyDmgMelee")
        NewDamageSettingLine("$wand_editor_dmg_holy", "DummyDmgHoly")
        NewDamageSettingLine("$wand_editor_dmg_heal", "DummyDmgHeal")
        NewDamageSettingLine("$wand_editor_dmg_physics_hit", "DummyDmgPhysicsHit")
        NewDamageSettingLine("$wand_editor_dmg_curse", "DummyDmgCurse")
        NewDamageSettingLine("$wand_editor_dmg_toxic", "DummyDmgToxic")
		NewDamageSettingLine("$wand_editor_dmg_poison", "DummyDmgPoison")
        GuiLayoutEnd(UI.gui)

        GuiLayoutBeginHorizontal(UI.gui, 0, ContainerH - 12, true, 4, 2)

		GuiZSetForNextWidget(UI.gui, UI.GetZDeep())
		local spwan_left_click = GuiButton(UI.gui,UI.NewID("SettingDummySpwan"),3,0,GameTextGet("$wand_editor_options_spwan_dummy"))
        GuiTooltip(UI.gui, GameTextGet("$wand_editor_options_spwan_dummy_tips"), "")

		if spwan_left_click then
            local shift = InputIsKeyDown(Key_LSHIFT) or InputIsKeyDown(Key_RSHIFT)
            local px, py = Compose(EntityGetTransform, GetPlayer)()
			local dummy = EntityLoad("mods/wand_editor/files/entity/dummy_target.xml", px, py)
            if not shift then
                local dmgModel = EntityGetFirstComponentIncludingDisabled(dummy, "DamageModelComponent")
                local SetDmgMult = Curry(ComponentObjectSetValue2, 4)(dmgModel, "damage_multipliers")
                SetDmgMult("projectile", GetDmgNum("DummyDmgProj"))
                SetDmgMult("explosion", GetDmgNum("DummyDmgExpl"))
                SetDmgMult("electricity", GetDmgNum("DummyDmgElectric"))
                SetDmgMult("slice", GetDmgNum("DummyDmgSlice"))
				SetDmgMult("drill",GetDmgNum("DummyDmgDrill"))
				SetDmgMult("fire",GetDmgNum("DummyDmgFire"))
				SetDmgMult("ice",GetDmgNum("DummyDmgIce"))
                SetDmgMult("melee", GetDmgNum("DummyDmgMelee"))
				SetDmgMult("holy",GetDmgNum("DummyDmgHoly"))
                SetDmgMult("healing", GetDmgNum("DummyDmgHeal"))
                SetDmgMult("physics_hit", GetDmgNum("DummyDmgPhysicsHit"))
                SetDmgMult("curse", GetDmgNum("DummyDmgCurse"))
				SetDmgMult("radioactive", GetDmgNum("DummyDmgToxic"))
				SetDmgMult("poison", GetDmgNum("DummyDmgPoison"))
			end
		end

		GuiZSetForNextWidget(UI.gui, UI.GetZDeep())
		local del_left_click = GuiButton(UI.gui,UI.NewID("SettingDummyDel"),3,0,GameTextGet("$wand_editor_options_del_dummy"))
		if del_left_click then
            local t = EntityGetWithTag("polymorphable_NOT")
			for _,v in pairs(t)do
				if EntityGetName(v) == "wand_editor_dummy_target" then
					EntityKill(v)
				end
			end
		end
        GuiTooltip(UI.gui, GameTextGet("$wand_editor_options_del_dummy_tips"), "")

		GuiZSetForNextWidget(UI.gui, UI.GetZDeep())
		local reset_left_click = GuiButton(UI.gui,UI.NewID("SettingDummyReset"),3,0,GameTextGet("$wand_editor_options_reset_options"))
		if reset_left_click then
			UI.TextInputRestore("DummyDmgProj")
			UI.TextInputRestore("DummyDmgExpl")
			UI.TextInputRestore("DummyDmgElectric")
			UI.TextInputRestore("DummyDmgSlice")
			UI.TextInputRestore("DummyDmgDrill")
			UI.TextInputRestore("DummyDmgFire")
			UI.TextInputRestore("DummyDmgIce")
			UI.TextInputRestore("DummyDmgMelee")
			UI.TextInputRestore("DummyDmgHoly")
			UI.TextInputRestore("DummyDmgHeal")
			UI.TextInputRestore("DummyDmgPhysicsHit")
			UI.TextInputRestore("DummyDmgCurse")
			UI.TextInputRestore("DummyDmgToxic")
			UI.TextInputRestore("DummyDmgPoison")
		end
		GuiLayoutEnd(UI.gui)
    end)
	
	UI.DrawScrollContainer("SpwanDummyOptions", false)
end

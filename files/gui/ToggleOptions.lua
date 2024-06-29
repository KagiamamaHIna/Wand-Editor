dofile_once("mods/wand_editor/files/misc/bygoki/lib/helper.lua")
local old_thousands_separator = thousands_separator
local thousands_separator = function(num)
    if num > 1e15 then
        return string.lower(tostring(num))
    else
        return old_thousands_separator(string.format("%.2f", num))
    end
end

local function get_screen_position( x, y )
	local screen_width, screen_height = GuiGetScreenDimensions( UI.gui )
	local camera_x, camera_y = GameGetCameraPos()
	local res_width = MagicNumbersGetValue( "VIRTUAL_RESOLUTION_X" )
	local res_height = MagicNumbersGetValue( "VIRTUAL_RESOLUTION_Y" )
	local ax = (x - camera_x) / res_width * screen_width
	local ay = (y - camera_y) / res_height * screen_height
	return ax + screen_width * 0.5, ay + screen_height * 0.5
end

function DrawDamageInfo()
    GuiLayoutBeginLayer(UI.gui)
    GuiLayoutBeginVertical(UI.gui, UI.ScreenWidth * 0.5, 0, true)
    GuiLayoutAddVerticalSpacing(UI.gui, 5)
	
	local player_projectiles = EntityGetWithTag("projectile_player") or {}
	local highest_projectile_damage = 0
	local highest_damage_projectile = nil
	local total_projectile_damage = 0
	local total_projectiles = #player_projectiles
	for k,v in pairs( player_projectiles ) do
		local projectile = EntityGetFirstComponent( v, "ProjectileComponent" )
		if projectile then
			local damage = ComponentGetValue2( projectile, "damage" ) * 25
			if damage > highest_projectile_damage then
				highest_damage_projectile = v
				highest_projectile_damage = damage
			end
			total_projectile_damage = total_projectile_damage + damage
		end
	end
	GuiOptionsAddForNextWidget(UI.gui, GUI_OPTION.Align_HorizontalCenter)
    GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_total_proj_dmg") .. thousands_separator(total_projectile_damage))

	GuiOptionsAddForNextWidget(UI.gui, GUI_OPTION.Align_HorizontalCenter)
    GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_total_proj") .. thousands_separator(total_projectiles))
	
    local highest_dps = GlobalsGetValue(ModID .. "highest_dps", "")--渲染dps数据，伤害来自假人
    if #highest_dps > 0 then
		GuiOptionsAddForNextWidget(UI.gui, GUI_OPTION.Align_HorizontalCenter)
        GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_dps") .. highest_dps)
	end

	local total_damage = GlobalsGetValue(ModID .."total_damage","" )--渲染总伤数据，伤害来自假人
    if #total_damage > 0 then
		GuiOptionsAddForNextWidget(UI.gui, GUI_OPTION.Align_HorizontalCenter)
        GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_total_damage") .. total_damage)
    end

	GuiLayoutEnd(UI.gui)
    GuiLayoutEndLayer(UI.gui)
	if highest_damage_projectile ~= nil then
        local esx, esy = get_screen_position(EntityGetTransform(highest_damage_projectile))
        GuiText(UI.gui, esx, esy, thousands_separator(highest_projectile_damage))
    end
end

local function PickerGap(gap)
	return 19 + gap * 22
end

function ToggleOptionsCB(_, _, _, iy, this_enable)
    if not this_enable then
        return
    end
	UI.MoveImagePicker("ProtectionAll", PickerGap(0), iy + 20, 8, 0, GameTextGet("$wand_editor_protection_all"),
        "mods/wand_editor/files/gui/images/protection_all.png", nil, nil, nil, true, true, true)
		
	UI.MoveImagePicker("ProtectionPoly", PickerGap(1), iy + 20, 8, 0, GameTextGet("$wand_editor_protection_poly"),
        "mods/wand_editor/files/gui/images/protection_poly.png", nil, nil, nil, true, true, true)

	UI.MoveImagePicker("LockHP", PickerGap(2), iy + 20, 8, 0, GameTextGet("$wand_editor_lock_hp"),
        "mods/wand_editor/files/gui/images/lock_hp.png", nil, nil, nil, true, true, true)

	UI.MoveImagePicker("DamageInfo", PickerGap(3), iy + 20, 8, 0, GameTextGet("$wand_editor_damage_info"),
        "mods/wand_editor/files/gui/images/damage_info.png", nil, nil, nil, true, true, true)
		
	UI.MoveImagePicker("NoRecoil", PickerGap(4), iy + 20, 8, 0, GameTextGet("$wand_editor_no_recoil"),
        "mods/wand_editor/files/gui/images/no_recoil.png", nil, nil, nil, true, true, true)

	UI.MoveImagePicker("DisableParticles", PickerGap(5), iy + 20, 8, 0, GameTextGet("$wand_editor_no_particles"),
        "mods/wand_editor/files/gui/images/disable_particles.png", nil, nil, nil, true, true, true)

	UI.MoveImagePicker("DisableProj", PickerGap(6), iy + 20, 8, 0, GameTextGet("$wand_editor_no_proj"),
        "mods/wand_editor/files/gui/images/disable_projectiles.png", nil, nil, nil, true, true, true)

	UI.MoveImagePicker("UnlimitedSpells", PickerGap(0), iy + 40, 8, 0, GameTextGet("$wand_editor_unlimited_spells"),
        "mods/wand_editor/files/gui/images/unlimited_spells.png", nil, nil, nil, true, true, true)

	UI.MoveImagePicker("EditWandsEverywhere", PickerGap(1), iy + 40, 8, 0, GameTextGet("$wand_editor_edit_wands_everywhere"),
        "mods/wand_editor/files/gui/images/edit_wands_everywhere.png", nil, nil, nil, true, true, true)

	UI.MoveImagePicker("AlwaysDrawWandEditBox", PickerGap(2), iy + 40, 8, 0, GameTextGet("$wand_editor_always_draw_wand_edit_box"),
        "mods/wand_editor/files/gui/images/always_draw_wand_edit_box.png", nil, nil, nil, true, true, true)
	
	UI.MoveImagePicker("KeyBoardInput", PickerGap(3)+2, iy + 40, 8, 0, GameTextGet("$wand_editor_keyboard_input"),
        "mods/wand_editor/files/gui/images/keyboard_input.png", nil, nil, nil, true, true, true)
end

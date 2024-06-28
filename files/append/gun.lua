local __wand_editor_register_action = register_action

function register_action( state )--无后坐力实现
    if not reflecting then
        if ModSettingGet("wand_editor".."NoRecoil") then shot_effects.recoil_knockback = 0; end
    end
    __wand_editor_register_action( state )
    return state
end

local __wand_editor_draw_shot = draw_shot

function draw_shot(...)--禁用施法
    if ModSettingGet("wand_editor" .. "DisableProj") then
        return
    end
	__wand_editor_draw_shot(...)
end

local __wand_editor__play_permanent_card = _play_permanent_card

function _play_permanent_card(...)--禁用施法
    if ModSettingGet("wand_editor" .. "DisableProj") then
		gun.reload_time = 0
        return
    end
	__wand_editor__play_permanent_card(...)
end

local __wand_editor_StartReload= StartReload

function StartReload(...)
    if ModSettingGet("wand_editor" .. "DisableProj") then
        return
    end
	__wand_editor_StartReload(...)
end

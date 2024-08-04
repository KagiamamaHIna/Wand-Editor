dofile("data/scripts/lib/mod_settings.lua")

function mod_setting_bool_custom( mod_id, gui, in_main_menu, im_id, setting )
	local value = ModSettingGetNextValue( mod_setting_get_id(mod_id,setting) )
	local text = setting.ui_name .. " - " .. GameTextGet( value and "$option_on" or "$option_off" )

	if GuiButton( gui, im_id, mod_setting_group_x_offset, 0, text ) then
		ModSettingSetNextValue( mod_setting_get_id(mod_id,setting), not value, false )
	end

	mod_setting_tooltip( mod_id, gui, in_main_menu, setting )
end

function mod_setting_change_callback(mod_id, gui, in_main_menu, setting, old_value, new_value)
    print(tostring(new_value))
end
local csv = dofile_once("mods/wand_editor/files/libs/csv.lua")

local currentLang = csv(ModTextFileGetContent("mods/wand_editor/files/lang/lang.csv"))
local gameLang = csv(ModTextFileGetContent("data/translations/common.csv"))
local CurrentMap = {}
for v,_ in pairs(gameLang.rowHeads) do--构建一个关联表用来查询键值
	if v ~= "" then
		local tempKey = gameLang.get("current_language",v)
		CurrentMap[tempKey] = v
	end
end
local function GetText(key) --获取文本
	if key == "" then
		return key
	end
	local GameKey
    local GameTextLangGet = GameTextGet("$current_language")
	GameKey = CurrentMap[GameTextLangGet]
    if GameKey == nil then
        GameKey = "en"
    end
    local result = currentLang.get(key, GameKey)
	result = string.gsub(result, [[\n]], "\n")
	if result == nil or result == "" then
        result = currentLang.get(key, "en")
	end
	return result
end

---监听访问
---@param t table
---@param callback function
local function TableListener(t, callback)
    local function NewListener()
        local __data = {}
        local deleteList = {}
        for k, v in pairs(t) do
            __data[k] = v
            deleteList[#deleteList + 1] = k
        end
        for _, v in pairs(deleteList) do
            t[v] = nil
        end
        local result = {
            __newindex = function(table, key, value)
                local temp = callback(key, value)
                value = temp or value
                rawset(__data, key, value)
                rawset(table, key, nil)
            end,
            __index = function(table, key)
                local temp = callback(key, rawget(__data, key))
				if temp == nil then
					return rawget(__data, key)
                else
					return temp
				end
            end,
            __call = function()
                return __data
            end
        }
        return result
    end
	setmetatable(t, NewListener())
end

local function Setting(t)
    TableListener(t, function(key, value)
        if key == "ui_name" or key == "ui_description" then
            local result = GetText(value)
            return result
        end
    end)
    return t
end
local function GetTextOrKey(key)
    local result = GetText(key)
    return result or key
end

local IKnowWhatImDoing_wand_editor_reset_btn_pos = false

local mod_id = "wand_editor"
mod_settings_version = 1
mod_settings = 
{
	Setting({
        id = "cache_spell_data",
		ui_name = "wand_editor_no_spell_cache",
		ui_description = "wand_editor_no_spell_cache_tip",
		value_default = true,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    }),
	Setting({
        id = "locked_target_pos",
		ui_name = "wand_editor_locked_target_pos",
		ui_description = "wand_editor_locked_target_pos_tip",
		value_default = true,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    }),
	Setting({
        id = "remove_fog_of_war",
		ui_name = "wand_editor_remove_fog_of_war",
		ui_description = "wand_editor_remove_fog_of_war_tip",
		value_default = false,
        scope = MOD_SETTING_SCOPE_RUNTIME_RESTART,
    }),
    Setting({
        id = "reset_all_btn_in_setting",
		ui_name = "",
		ui_description = "",
        ui_fn = function(mod_id, gui, in_main_menu, im_id, setting)
			GuiIdPushString(gui,"wand_editor")
            local click = GuiButton(gui, 1, 0, 0, GetTextOrKey("wand_editor_reset_btn_pos"))
            local _, _, hover = GuiGetPreviousWidgetInfo(gui)
			if not hover and IKnowWhatImDoing_wand_editor_reset_btn_pos then
				IKnowWhatImDoing_wand_editor_reset_btn_pos = false
			end
            if click and not ModSettingGet("wand_editor.reset_all_btn") and not IKnowWhatImDoing_wand_editor_reset_btn_pos then
                IKnowWhatImDoing_wand_editor_reset_btn_pos = true
			elseif click and IKnowWhatImDoing_wand_editor_reset_btn_pos then
                ModSettingSet("wand_editor.reset_all_btn", true)
				IKnowWhatImDoing_wand_editor_reset_btn_pos = false
            end
			if IKnowWhatImDoing_wand_editor_reset_btn_pos then
				GuiTooltip(gui,GetTextOrKey("wand_editor_reset_btn_pos_IKnowWhatImDoing"),"")
            else
				GuiTooltip(gui,GetTextOrKey("wand_editor_reset_btn_pos_tip"),"")
			end
			GuiIdPop(gui)
		end
    }),
	--[[
	Setting({
        category_id = "load_other_wand_box_btns",
		ui_name = "wand_editor_load_other_wand_box",
        ui_description = "",
		foldable = true,
		settings = {
			Setting({
				id = "load_spell_lab",
				ui_name = "",
				ui_description = "",
				ui_fn = function(mod_id, gui, in_main_menu, im_id, setting)
					GuiIdPushString(gui,"wand_editor")
                    local click = GuiButton(gui, 2, 0, 0, GetTextOrKey("wand_editor_load_spell_lab_wand_box"))
					GuiTooltip(gui,GetTextOrKey("wand_editor_load_spell_lab_wand_box_tip"),"")
			
					GuiIdPop(gui)
				end,
            }),
			Setting({
				id = "load_wands_conn",
				ui_name = "",
				ui_description = "",
				ui_fn = function(mod_id, gui, in_main_menu, im_id, setting)
                    GuiIdPushString(gui, "wand_editor")
					local click = GuiButton(gui, 3, 0, 0, GetTextOrKey("wand_editor_load_wands_conn_wand_box"))
                    GuiTooltip(gui, GetTextOrKey("wand_editor_load_wands_conn_wand_box_tip"), "")
			
					GuiIdPop(gui)
				end,
            }),
			Setting({
				id = "load_spell_lab_shug",
				ui_name = "",
				ui_description = "",
				ui_fn = function(mod_id, gui, in_main_menu, im_id, setting)
					GuiIdPushString(gui,"wand_editor")
					local click = GuiButton(gui, 4, 0, 0, GetTextOrKey("wand_editor_load_spell_lab_shug_wand_box"))
                    GuiTooltip(gui, GetTextOrKey("wand_editor_load_spell_lab_shug_wand_box_tip"), "")
					if click then
						
					end
					GuiIdPop(gui)
				end,
			})
		}
    }),]]
}

function ModSettingsUpdate( init_scope )
	local old_version = mod_settings_get_version( mod_id )
	mod_settings_update( mod_id, mod_settings, init_scope )
end

function ModSettingsGuiCount()
	return mod_settings_gui_count( mod_id, mod_settings )
end

function ModSettingsGui( gui, in_main_menu )
	mod_settings_gui( mod_id, mod_settings, gui, in_main_menu )
end

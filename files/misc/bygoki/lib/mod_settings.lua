dofile_once("mods/wand_editor/files/libs/define.lua")
function setting_get( key ) return ModSettingGet( ModID..key ); end
function setting_set( key, value ) if value ~= nil then return ModSettingSet( ModID..key, value ); end end
function setting_clear( key ) return ModSettingRemove(ModID..key ); end

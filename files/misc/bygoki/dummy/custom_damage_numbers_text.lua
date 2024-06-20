dofile_once( "mods/wand_editor/files/misc/bygoki/helper.lua" );
dofile_once( "mods/wand_editor/files/misc/bygoki/lib/variables.lua" );
last_text = last_text or "";
local entity = GetUpdatedEntityID();
local current_target = EntityGetParent( entity );
local current_text = EntityGetVariableString( current_target, "gkbrkn_custom_damage_numbers_text", "" );
if current_target ~= 0 and last_text ~= current_text then
    last_text = current_text;
    local width,height = EntityGetFirstHitboxSize( current_target );
    local sprite = EntityGetFirstComponent( entity, "SpriteComponent", "gkbrkn_custom_damage_number" );
    if sprite then
        ComponentSetValue2( sprite, "offset_x", #current_text * 2 - 2 );
        ComponentSetValue2( sprite, "offset_y", height * 2 + 12 );
        ComponentSetValue2( sprite, "text", current_text );
        EntityRefreshSprite( entity, sprite );
    end
end

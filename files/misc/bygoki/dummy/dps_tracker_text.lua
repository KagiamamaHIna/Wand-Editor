dofile_once( "mods/wand_editor/files/misc/bygoki/helper.lua" );
dofile_once("mods/wand_editor/files/misc/bygoki/lib/variables.lua");
dofile_once("mods/wand_editor/files/libs/fn.lua")
last_text = last_text or "";
local SrcPath = "mods/wand_editor/files/misc/bygoki/font/font_small_numbers.xml"
local sprite_highest = EntityGetFirstComponentIncludingDisabled(entity, "SpriteComponent", "gkbrkn_dps_tracker_highest");
local sprite_true = EntityGetFirstComponentIncludingDisabled(entity, "SpriteComponent", "gkbrkn_dps_tracker_true");
local sprite_damage_number = EntityGetFirstComponentIncludingDisabled(entity, "SpriteComponent", "gkbrkn_custom_damage_number");

local entity = GetUpdatedEntityID();
local current_target = EntityGetParent( entity );
local current_text = EntityGetVariableString( current_target, "gkbrkn_dps_tracker_text", "" );
if current_target ~= 0 and last_text ~= current_text then
    last_text = current_text;
    local width,height = EntityGetFirstHitboxSize( current_target );
    local sprite = EntityGetFirstComponent( entity, "SpriteComponent", "gkbrkn_dps_tracker" );
    if sprite and current_text ~= "inf" then
        ComponentSetValue2( sprite, "offset_x", #current_text * 2 - 2 );
        ComponentSetValue2(sprite, "offset_y", height * 2 - 12);
        ComponentSetValue2(sprite, "text", current_text);
        ComponentSetValue2(sprite, "is_text_sprite", true);
        ComponentSetValue2(sprite, "image_file", SrcPath);
		EntitySetComponentIsEnabled(entity, sprite_highest, true)
        EntitySetComponentIsEnabled(entity, sprite_true, true)
		EntitySetComponentIsEnabled(entity, sprite_damage_number, true)
        EntityRefreshSprite(entity, sprite);
	elseif sprite and current_text == "inf" then
        ComponentSetValue2(sprite, "is_text_sprite", false);
		ComponentSetValue2( sprite, "offset_x", 0);
        ComponentSetValue2(sprite, "offset_y", 0);
        ComponentSetValue2(sprite, "image_file", "mods/wand_editor/files/entity/dummy/inf_small.xml");
        EntitySetComponentIsEnabled(entity, sprite_highest, false)
        EntitySetComponentIsEnabled(entity, sprite_true, false)
		EntitySetComponentIsEnabled(entity, sprite_damage_number, false)
        EntityRefreshSprite(entity, sprite);
    end
end

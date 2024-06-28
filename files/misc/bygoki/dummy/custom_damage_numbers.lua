dofile_once( "mods/wand_editor/files/misc/bygoki/helper.lua" );
dofile_once( "mods/wand_editor/files/misc/bygoki/lib/helper.lua" );
dofile_once( "mods/wand_editor/files/misc/bygoki/lib/variables.lua" );
local last_damage_frame = {};
local old_thousands_separator = thousands_separator
thousands_separator = function(num)
    if num > 1e15 then
        return string.lower(tostring(num))
    else
        return old_thousands_separator(string.format("%.2f", num));
    end
end

function damage_received( damage, message, entity_thats_responsible, is_fatal )
    local entity = GetUpdatedEntityID();
    if EntityHasNamedVariable( entity, "gkbrkn_always_show_damage_numbers" ) or is_fatal == false then
        local now = GameGetFrameNum();
        if now - ( last_damage_frame[entity] or 0 ) > 180 then
            EntitySetVariableNumber( entity, "gkbrkn_total_damage", 0 );
        end
        last_damage_frame[entity] = now;
        local total_damage = EntityGetVariableNumber(entity, "gkbrkn_total_damage", 0) + damage;
        EntitySetVariableNumber( entity, "gkbrkn_total_damage", total_damage );
        local damage_text = thousands_separator(total_damage * 25 );
        EntitySetVariableString(entity, "gkbrkn_custom_damage_numbers_text", damage_text);
    else
        local sprites = EntityGetComponentIncludingDisabled(entity,"SpriteComponent") or {};
        for k,v in pairs( sprites ) do
            if ComponentGetValue2( v, "is_text_sprite" ) then
                EntityRemoveComponent( entity, v );
            end
        end
    end
end

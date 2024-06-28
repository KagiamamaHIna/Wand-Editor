dofile_once("mods/wand_editor/files/misc/bygoki/lib/helper.lua")

function shot( projectile_entity )
    if ModSettingGet("wand_editor".."DisableParticles") == true then
        reduce_particles( projectile_entity, true )
    end
    EntityAddTag( projectile_entity, "projectile_player" )
end

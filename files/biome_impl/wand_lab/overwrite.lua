local entity = GetUpdatedEntityID();
local x, y = EntityGetTransform( entity );
EntityLoad( "mods/wand_editor/files/entity/dummy_target.xml", x - 100, y );
EntityLoad( "mods/wand_editor/files/entity/dummy_target.xml", x + 100, y );


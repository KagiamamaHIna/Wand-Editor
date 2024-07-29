local entity = GetUpdatedEntityID();
local x, y = EntityGetTransform( entity );
EntityLoad( "mods/wand_editor/files/entity/dummy_target.xml", x - 100, y );
EntityLoad( "mods/wand_editor/files/entity/dummy_target.xml", x + 100, y );
if EntityGetWithName("WandEditorSpellLabVisualizer") == 0 then
	local id = EntityLoad("data/entities/buildings/workshop_spell_visualizer.xml", x - 78, y - 50);
	EntitySetName(id,"WandEditorSpellLabVisualizer")
end

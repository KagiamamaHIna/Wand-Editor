dofile_once("mods/wand_editor/files/libs/fn.lua")
local entity = GetUpdatedEntityID()
if ModSettingGet(ModID..".locked_target_pos") then
    local x = GetStorageComp(entity, "fix_pos_x")
	local y = GetStorageComp(entity, "fix_pos_y")
    if x == nil or y == nil then
        x, y = EntityGetTransform(entity)
        AddSetStorageComp(entity, "fix_pos_x", x)
        AddSetStorageComp(entity, "fix_pos_y", y)
    end
    EntitySetTransform(entity, x, y)
end

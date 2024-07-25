dofile_once("mods/wand_editor/files/libs/fn.lua")
local entity = GetUpdatedEntityID()
local x = GetStorageComp(entity, "fix_pos_x")
local y
if x == nil then--初始化
	x, y = EntityGetTransform(entity)
	AddSetStorageComp(entity, "fix_pos_x", x)
	AddSetStorageComp(entity, "fix_pos_y", y)
end
if ModSettingGet(ModID..".locked_target_pos") then--假设没有模组更改
    y = GetStorageComp(entity, "fix_pos_y")
	EntitySetTransform(entity, x, y)
end

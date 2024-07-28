dofile_once("mods/wand_editor/files/libs/fn.lua")
local player = GetPlayer()
local entity = GetUpdatedEntityID()

--通过计算来动态删增需要的随编buff
local NoEditCount = GameGetGameEffectCount(player, "NO_WAND_EDITING")
local EditCount = GameGetGameEffectCount(player, "EDIT_WANDS_EVERYWHERE")

if EditCount <= NoEditCount then
    for _ = EditCount, NoEditCount do
        EntityAddComponent2(entity, "GameEffectComponent", { effect = "EDIT_WANDS_EVERYWHERE", frames = -1 })
    end
elseif (EditCount - 1) > NoEditCount then
    local list = EntityGetComponent(entity, "GameEffectComponent")
	if list == nil then--为空就退出
		return
	end
    for i = NoEditCount, EditCount do
        local id = list[i]
		if id == nil then--越界了就退出
			return
		end
        EntityRemoveComponent(entity, id)
    end
end

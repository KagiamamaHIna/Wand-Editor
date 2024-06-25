local function DrawWandSlot(id, k, wand)
    GuiImage(UI.gui, UI.NewID(id .. tostring(k)), 0, 0, wand.sprite_file, 1, 1, 0, math.rad(-57.5))
end

---返回法杖仓库大小
---@return integer
local function GetWandDepotSize()
	return ModSettingGet(ModID.."WandDepotSize")
end

--设置法杖仓库大小(不影响实际，单纯的设置)
local function SetWandDepotSize(num)
	ModSettingSet(ModID.."WandDepotSize", num)
end

---获得法杖仓库表
---@param index integer
---@return table
local function GetWandDepot(index)
    local size = GetWandDepotSize()
    if index <= size then
		return Compose(loadstring, ModSettingGet)(ModID.."WandDepot"..tostring(index))()
	end
    error("wand depot index out of bounds:"..tostring(index))
	return {}
end

---设置法杖仓库表
---@param t table
---@param index integer
local function SetWandDepotLua(t, index)
    local size = GetWandDepotSize()
	if index <= size then
		ModSettingSet(ModID .. "WandDepot"..tostring(index), "return {\n" .. SerializeTable(t) .. "}")
    else
        error("wand depot index out of bounds"..tostring(index))
	end
end

local function NewWandDepot()
	local index = GetWandDepotSize()
    SetWandDepotSize(index + 1)
    index = index + 1
    ModSettingSet(ModID .. "WandDepot" .. tostring(index), "return {}")
	return {}
end

local function RemoveWandDepot(index)
    local max = GetWandDepotSize()
    for i = index, max - 1 do
        SetWandDepotLua(GetWandDepot(i + 1), i)
    end
    ModSettingRemove(ModID .. "WandDepot" .. tostring(max))
	SetWandDepotSize(max-1)
end

function WandDepotCB(_, _, _, _, this_enable)
    if not this_enable then
        return
    end
	if UI.UserData["WandDepotCurrentIndex"] == nil then
		UI.UserData["WandDepotCurrentIndex"] = 1
	end
    local CurrentIndex = UI.UserData["WandDepotCurrentIndex"]
    if GetWandDepotSize() == 0 then
        NewWandDepot()
    end
    local CurrentTable = GetWandDepot(CurrentIndex)
	
end

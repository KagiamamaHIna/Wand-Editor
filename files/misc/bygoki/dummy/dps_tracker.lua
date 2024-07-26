dofile_once( "mods/wand_editor/files/misc/bygoki/helper.lua" );
dofile_once( "mods/wand_editor/files/misc/bygoki/lib/helper.lua" );
dofile_once("mods/wand_editor/files/misc/bygoki/lib/mod_settings.lua");
dofile_once("mods/wand_editor/files/libs/fn.lua")

---获得Storage组件和对应值
---@param entity integer EntityID
---@param VariableName string
---@return any|nil
---@return integer|nil
local function GetFloatStorageComp(entity, VariableName)
	local comps = EntityGetComponent(entity, "VariableStorageComponent")
	if comps == nil then
		return
	end
	for _, comp in pairs(comps) do --遍历存储组件表
		local name = ComponentGetValue2(comp, "name")
		if name == VariableName then --如果是状态就取值
			local value = ComponentGetValue2(comp, "value_float")
			return value, comp
		end
	end
end

---增加并设置Storage
---@param entity integer
---@param i_name string
---@param i_value any
---@return integer|nil
local function AddSetFloatStorageComp(entity, i_name, i_value)
	if entity == nil or not EntityGetIsAlive(entity) then
		return
	end
	return EntityAddComponent(entity, "VariableStorageComponent", { name = i_name, value_float = i_value })
end

---设置Storage，并返回组件
---@param entity integer
---@param VariableName string
---@param i_value any
---@return integer|nil
local function SetFloatStorageComp(entity, VariableName, i_value)
	local comps = EntityGetComponent(entity, "VariableStorageComponent")
	if comps == nil then
		return
	end
	for _, comp in pairs(comps) do --遍历存储组件表
		local name = ComponentGetValue2(comp, "name")
		if name == VariableName then --如果是就取值
			ComponentSetValue2(comp, "value_float", i_value)
			return comp
		end
	end
end

function GetValue(entity, id)
	local result = GetFloatStorageComp(entity, id)
    if result == nil then
        AddSetFloatStorageComp(entity, id, 0)
        result = 0
    end
	return result
end

function damage_received( damage, message, entity_thats_responsible, is_fatal )
    local now = GameGetFrameNum();
    local now_true = GameGetRealWorldTimeSinceStarted();
    local entity = GetUpdatedEntityID();

    local current = GetValue(entity, "current")
	local current_true = GetValue(entity, "current_true")
    local first_hit_frame = GetValue(entity, "first_hit_frame")
    local total_damage = GetValue(entity, "total_damage")
	local reset_frame = GetValue(entity, "reset_frame")
	local first_hit_time = GetValue(entity, "first_hit_time")

    local damage_models = EntityGetComponent( entity, "DamageModelComponent" ) or {};
	
    for _,damage_model in pairs(damage_models) do
        local max_hp = ComponentGetValue2( damage_model, "max_hp" );
        ComponentSetValue2( damage_model, "max_hp", 4 );
        ComponentSetValue2( damage_model, "hp", math.max( 4, damage * 1.1 ) );
    end
    --local x,y = EntityGetTransform( entity );
    --local did_hit, hit_x, hit_y = RaytracePlatforms( x, y - 1, x, y );
    --if did_hit then
    --    EntityApplyTransform( entity, x, y - 5 );
    --end

    -- reset tracker after 10 frames of dps
    if now >= reset_frame or (now - first_hit_frame) > 600 then
        total_damage = 0;
        current_true = 0;
        current = 0;
        first_hit_frame = now;
        first_hit_time = now_true;
        EntitySetVariableNumber( entity, "gkbrkn_dps_tracker_highest", 0 );
    end
    total_damage = total_damage + damage;
    reset_frame = now + 60;
    current = total_damage / math.ceil( math.max( now - first_hit_frame, 1 ) / 59 );
    current_true = total_damage / math.max(now_true - first_hit_time, 1);
	local old_thousands_separator = thousands_separator
    local thousands_separator = function(num)
        if num > 1e15 or -num > 1e15 then
            return string.lower(tostring(num))
        else
            return old_thousands_separator(string.format("%.2f", num));
        end
    end
	
    local highest_current = EntityGetVariableNumber( entity, "gkbrkn_dps_tracker_highest", 0 );
    local damage_text
	if IsINF(current * 25) then--thousands_separator
        damage_text = "inf"
	elseif current * 25 == -math.huge then
		damage_text = "-inf"
    else
		damage_text = thousands_separator(current * 25 );
	end
    local damage_text_true = thousands_separator(current_true * 25 );
    EntitySetVariableString( entity, "gkbrkn_dps_tracker_text", damage_text );
    EntitySetVariableString(entity, "gkbrkn_dps_tracker_text_true", damage_text_true);
    GlobalsSetValue(ModID .. "total_damage", thousands_separator(total_damage * 25))
	local flag = false
    if current < 0 and highest_current <= 0 and current < highest_current then
        flag = true
    end
	if current > 0 and current > highest_current then
		flag = true
	end
	if flag then
        EntitySetVariableNumber( entity, "gkbrkn_dps_tracker_highest", current );
        EntitySetVariableString(entity, "gkbrkn_dps_tracker_text_highest", thousands_separator(current * 25));
		GlobalsSetValue(ModID .. "highest_dps", damage_text);
    end
    add_frame_time(GameGetRealWorldTimeSinceStarted() - now_true);

	SetFloatStorageComp(entity, "current", current)
	SetFloatStorageComp(entity, "current_true", current_true)
    SetFloatStorageComp(entity, "first_hit_frame", first_hit_frame)
    SetFloatStorageComp(entity, "total_damage", total_damage)
	SetFloatStorageComp(entity, "reset_frame", reset_frame)
	SetFloatStorageComp(entity, "first_hit_time", first_hit_time)
end

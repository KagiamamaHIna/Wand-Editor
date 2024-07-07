function GUIUpdate()
	if UI == nil then
		--初始化
		---@class Gui
        UI = dofile_once("mods/wand_editor/files/libs/gui.lua")
		
		dofile_once("mods/wand_editor/files/libs/fn.lua")
		dofile_once("data/scripts/lib/utilities.lua")
		dofile_once("mods/wand_editor/files/gui/SpellsScroll.lua")
        dofile_once("mods/wand_editor/files/gui/WandContainer.lua")
        dofile_once("mods/wand_editor/files/gui/WandBuilder.lua")
        dofile_once("mods/wand_editor/files/gui/WandDepot.lua")
		dofile_once("mods/wand_editor/files/gui/TargetDummyGUI.lua")
		dofile_once("mods/wand_editor/files/gui/ToggleOptions.lua")
		UI.UserData["HasSpellMove"] = false
		local data = dofile_once("mods/wand_editor/files/gui/GetSpellData.lua") --读取法术数据
		local spellData = data[1]
		local TypeToSpellList = data[2]
		local ZDeepest = UI.GetZDeep()
		---绘制一个悬浮法术
		---@param x number
		---@param y number
		---@param sprite string
		---@param id string
		function DrawFloatSpell(x, y, sprite, id)
			local hasMove = UI.UserData["HasSpellMove"]
			if not hasMove and not UI.GetNoMoveBool() then
				UI.UserData["FloatSpellID"] = id
				UI.UserData["HasSpellMove"] = true
				UI.TickEventFn["MoveSpellFn"] = function()          --分离出一个事件，用于表示法术点击后的效果
					local click = InputIsMouseButtonDown(Mouse_right)
					if click or GameIsInventoryOpen() then          --右键取消，或打开物品栏取消
						if GameIsInventoryOpen() and UI.UserData["UpSpellIndex"] then --如果是点击之前的法术并且打开了物品栏，恢复法术
							SetTableSpells(UI.UserData["UpSpellIndex"][2], UI.UserData["FloatSpellID"],
								UI.UserData["UpSpellIndex"][1], UI.UserData["UpSpellIndex"][4], false)
							InitWand(UI.UserData["UpSpellIndex"][2], UI.UserData["UpSpellIndex"][3])
						end
						UI.OnMoveImage("MoveSpell", x, y, sprite, true)
						UI.TickEventFn["MoveSpellFn"] = nil
						UI.UserData["HasSpellMove"] = false
						UI.UserData["FloatSpellID"] = nil
						UI.UserData["UpSpellIndex"] = nil
						return
					end
					--绘制悬浮图标
					local status = UI.OnMoveImage("MoveSpell", x, y, sprite, nil, nil, ZDeepest - 114514,
						UI.UserData["SpellHoverEnable"],
						function(movex, movey)
							GuiZSetForNextWidget(UI.gui, ZDeepest - 114513)
							GuiImage(UI.gui, UI.NewID("MoveSpell_BG"), movex - 2, movey - 2,
								SpellTypeBG[spellData[id].type], 1, 1)                                         --绘制背景
						end)
					if not UI.UserData["WandContainerHasHover"] and InputIsMouseButtonDown(Mouse_left) then
						UI.UserData["SpellHoverEnable"] = true
					end
					if not status then
						UI.TickEventFn["MoveSpellFn"] = nil
						if not UI.UserData["WandContainerHasHover"] then
							local worldx, worldy = DEBUG_GetMouseWorld()
							local spell = CreateItemActionEntity(id, worldx, worldy + 5)
							if UI.UserData["UpSpellIndex"] and UI.UserData["UpSpellIndex"][4] ~= nil then
								local uses_remaining = UI.UserData["UpSpellIndex"][4]
								local item = EntityGetFirstComponentIncludingDisabled(spell, "ItemComponent")
								ComponentSetValue2(item, "uses_remaining", uses_remaining)
							end
							UI.UserData["FloatSpellID"] = nil
							UI.UserData["UpSpellIndex"] = nil
						end
						UI.UserData["HasSpellMove"] = false
						UI.OnMoveImage("MoveSpell", x, y, sprite, true)
					end
				end
			end
		end
        local function PickerGap(gap)
            return 19 + gap * 22
        end
        local function ClickSound()
            GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", GameGetCameraPos())
        end
		UI.UserData["WandDepotHistoryEnable"] = false
		UI.PickerEnableList("WandBuilderBTN", "SpellDepotBTN", "WandDepotBTN", "ToggleOptionsBTN", "SpwanDummyBTN")
        UI.SetCheckboxEnable("shuffle_builder", false)
		UI.SetCheckboxEnable("update_image_builder", false)
		local MainCB = function(left_click, right_click, x, y, enable)
			if not enable then
				return
			end
			--开启状态
			UI.MoveImagePicker("SpellDepotBTN", PickerGap(0), y + 30, 8, 0, GameTextGet("$wand_editor_spell_depot"),
				"mods/wand_editor/files/gui/images/spell_depot.png", nil, SpellDepotClickCB, nil, true, nil,
				true)
				
			UI.MoveImagePicker("WandBuilderBTN", PickerGap(1), y + 30, 8, 0, GameTextGet("$wand_editor_wand_spawner"),
				"mods/wand_editor/files/gui/images/wand_builder.png", nil, WandBuilderCB, nil, true, nil,
				true)
			local WandDepotTips
			if UI.UserData["WandDepotHistoryEnable"] then
				WandDepotTips = GameTextGet("$wand_editor_wand_depot_history")
            else
				WandDepotTips = GameTextGet("$wand_editor_wand_depot")
			end
			UI.MoveImagePicker("WandDepotBTN", PickerGap(2), y + 30, 8, 0, WandDepotTips,
				"mods/wand_editor/files/gui/images/wand_depot.png", nil, WandDepotCB, nil, true, nil,
				true)

			UI.MoveImagePicker("SpwanDummyBTN", PickerGap(3), y + 30, 8, 0, GameTextGet("$wand_editor_spawn_dummy"),
				"mods/wand_editor/files/gui/images/spawn_target_dummy.png", nil, SpwanDummyCB, nil, true, nil,
                true)

			UI.MoveImagePicker("ToggleOptionsBTN", PickerGap(4), y + 30, 8, 0, GameTextGet("$wand_editor_toggle_options"),
				"mods/wand_editor/files/gui/images/toggle_options_icon.png", nil, ToggleOptionsCB, nil, true, nil,
                true)
				--[[
			GuiZSetForNextWidget(UI.gui, UI.GetZDeep())--生成假人于自身
			UI.MoveImageButton("SpwanDummy", PickerGap(4), y + 30,
				"mods/wand_editor/files/gui/images/spawn_target_dummy.png", nil, function()
					GuiTooltip(UI.gui, GameTextGet("$wand_editor_spawn_dummy"), "")
                end,
				function (click)
                    if not click then
                        return
                    end
					ClickSound()
					local px,py = Compose(EntityGetTransform, GetPlayer)()
                    EntityLoad("mods/wand_editor/files/entity/dummy_target.xml", px, py)
                end, false, true)]]

			GuiZSetForNextWidget(UI.gui, UI.GetZDeep())--清除投射物
			UI.MoveImageButton("ClearProj", PickerGap(5), y + 30,
				"mods/wand_editor/files/gui/images/clear_projectiles.png", nil, function()
					GuiTooltip(UI.gui, GameTextGet("$wand_editor_clear_proj"), "")
                end,
				function (click)
                    if not click then
                        return
                    end
                    ClickSound()
                    local t
					local CTRL = InputIsKeyDown(Key_LCTRL) or InputIsKeyDown(Key_RCTRL)
					if CTRL then
                        t = EntityGetWithTag("projectile") or {}
                    else
						t = EntityGetWithTag("projectile_player") or {}
					end
					for _,v in pairs(t) do
						local projectile = EntityGetFirstComponent( v, "ProjectileComponent" )
						if projectile ~= nil then
							ComponentSetValue2( projectile, "on_death_explode", false )
							ComponentSetValue2( projectile, "on_lifetime_out_explode", false )
						end
						EntityKill(v)
					end
                end, false, true)
				
			GuiZSetForNextWidget(UI.gui, UI.GetZDeep())--清除延迟
			UI.MoveImageButton("ClearWait", PickerGap(6), y + 30,
				"mods/wand_editor/files/gui/images/clear_wait.png", nil, function()
					GuiTooltip(UI.gui, GameTextGet("$wand_editor_clear_wait"), "")
                end,
				function (click)
                    if not click then
                        return
                    end
					ClickSound()
					local now = GameGetFrameNum()
                    local player = GetPlayer()
					for _,v in pairs( EntityGetWithTag("wand") ) do
						if EntityGetRootEntity( v ) == player then
							local ability = EntityGetFirstComponentIncludingDisabled( v, "AbilityComponent" )
							if ability then
								ComponentSetValue2( ability, "mReloadFramesLeft", 0 )
								ComponentSetValue2( ability, "mNextFrameUsable", now )
								ComponentSetValue2( ability, "mReloadNextFrameUsable", now )
							end
						end
					end
                end, false, true)
				
			GuiZSetForNextWidget(UI.gui, UI.GetZDeep())--刷新法术使用次数
			UI.MoveImageButton("RefreshUses", PickerGap(7), y + 30,
				"mods/wand_editor/files/gui/images/refresh_uses.png", nil, function()
					GuiTooltip(UI.gui, GameTextGet("$wand_editor_refresh_uses"), "")
                end,
				function (click)
                    if not click then
                        return
                    end
					ClickSound()
					GameRegenItemActionsInPlayer(GetPlayer())
				end, false, true)
		end
		---@param this Gui
        UI.TickEventFn["main"] = function(this) --我认为的主事件循环）
            if GameIsInventoryOpen() or GetPlayer() == nil then
                return
            end
			if InputIsKeyDown(Key_BACKSPACE) then
                local worldx, worldy = DEBUG_GetMouseWorld()
                local entitys = EntityGetInRadiusWithTag(worldx, worldy, 12, "polymorphable_NOT")
				for _,v in pairs(entitys)do
					if EntityGetName(v) == "wand_editor_dummy_target" then
                        EntityKill(v)
						GamePrint(GameTextGet("$wand_editor_kill_dummy_tip"))
					end
				end
			end

			GuiZSetForNextWidget(this.gui, UI.GetZDeep()) --设置深度，确保行为正确
			UI.MoveImagePicker("MainButton", 185, 12, 8, 0, GameTextGet("$wand_editor_main_button"),
				"mods/wand_editor/files/gui/images/menu.png", nil, MainCB, nil, false, nil, true)
        end
		
        UI.TickEventFn["RequestAvatar"] = function()
			if Cpp.PathExists("mods/wand_editor/cache/avatar.png") then--请求头像
				UI.TickEventFn["RequestAvatar"] = nil
			end
            if UI.UserData["RequestAvatarMode"] == nil then
                local Request = function()
                    local https = require("ssl.https")
					local ltn12 = require("ltn12")
                    require("github_mirror")
                    local code = 0
                    local Returns
					-- 准备sink，用于收集响应体数据
					local response_chunks = {}
                    local response_sink = ltn12.sink.table(response_chunks)
					local count = 0
                    while code ~= 200 and count <= 12 do--失败太多次就不请求了
                        Returns = { https.request {
							url = "https://avatars.githubusercontent.com/u/128758465",--?s=200&v200
							sink = response_sink,
						} }
                        code = Returns[2]
						count = count + 1
                    end
                    return response_chunks,code
                end
                local runner = effil.thread(Request)
				UI.UserData["RequestAvatarhandle"] = runner()
                UI.UserData["RequestAvatarMode"] = true
            elseif UI.UserData["RequestAvatarMode"] then
				local handle = UI.UserData["RequestAvatarhandle"]
                local status = handle:status()
                if status == "completed" then
                    local response_chunks, code = handle:get()
					if code == 200 then--如果正确请求了，那么就写入文件
						local file = io.open("mods/wand_editor/cache/avatar.png", "wb")
						for _, chunk in pairs(effil.dump(response_chunks)) do
							file:write(chunk)
						end
						file:close()
					end
                    UI.TickEventFn["RequestAvatar"] = nil
                    UI.UserData["RequestAvatarhandle"] = nil
				end
			end
		end

        UI.TickEventFn["ToggleOptions"] = function()
            if GetPlayer() == nil then --找不到玩家时禁止执行下一步
                return
            end
			local SkipDisableThrow = false
            if not UI.GetPickerStatus("QuickTP") or InputIsKeyDown(Key_LSHIFT) or InputIsKeyDown(Key_RSHIFT) then
				SkipDisableThrow = true
                local Active = GetActiveItem()
				if Active ~= nil then
                    local ItemAbility = EntityGetFirstComponentIncludingDisabled(Active, "AbilityComponent")
                    local HasData, comp = GetStorageComp(Active, "wand_editor_get_throw")
                    if ItemAbility ~= nil and comp ~= nil then
						local throw = ComponentGetValue2(ItemAbility, "throw_as_item")
                        if HasData == 1 then
                            ComponentSetValue2(ItemAbility, "throw_as_item", true)
                        elseif HasData == 0 and not throw then
                            ComponentSetValue2(ItemAbility, "throw_as_item", false)
                        end
                        EntityRemoveComponent(Active, comp)--只恢复这一次
					end
				end
			end
			if UI.GetPickerStatus("ProtectionBlindness") then
                local player = GetPlayer()
                local childs = EntityGetAllChildren(player)
				for _,v in pairs(childs or {})do
                    local GameEffects = EntityGetComponent(v, "GameEffectComponent")
					for _,effect in pairs(GameEffects or {})do
                        local effectName = ComponentGetValue2(effect, "effect")
						if effectName == "BLINDNESS" then
                            EntityKill(v)
							break
						end
					end
				end
			end
            if UI.GetPickerStatus("ProtectionAll") and EntityGetWithName("WandEditorProtectionAllEntity") == 0 then--无敌给予
                local player = GetPlayer()
                LoadGameEffectEntityTo(player, "mods/wand_editor/files/entity/protection_all.xml")
            elseif (not UI.GetPickerStatus("ProtectionAll")) and EntityGetWithName("WandEditorProtectionAllEntity") ~= 0 then
                EntityKill(EntityGetWithName("WandEditorProtectionAllEntity"))
            end

            if UI.GetPickerStatus("ProtectionPoly") and EntityGetWithName("WandEditorProtectionPolyEntity") == 0 then--变形免疫给予
                local player = GetPlayer()
                LoadGameEffectEntityTo(player, "mods/wand_editor/files/entity/protection_poly.xml")
            elseif (not UI.GetPickerStatus("ProtectionPoly")) and EntityGetWithName("WandEditorProtectionPolyEntity") ~= 0 then
                EntityKill(EntityGetWithName("WandEditorProtectionPolyEntity"))
            end
			
            if UI.GetPickerStatus("EditWandsEverywhere") and EntityGetWithName("WandEditorEditWandsEverywhereEntity") == 0 then --随编给予
                local player = GetPlayer()
                LoadGameEffectEntityTo(player, "mods/wand_editor/files/entity/edit_wands_everywhere.xml")
            elseif (not UI.GetPickerStatus("EditWandsEverywhere")) and EntityGetWithName("WandEditorEditWandsEverywhereEntity") ~= 0 then
                EntityKill(EntityGetWithName("WandEditorEditWandsEverywhereEntity"))
            end
			local t = GetStorageComp(nil,nil,true)
            local _, m, d = GameGetDateAndTimeLocal()
			if t[m][d] ~= nil and (not ModSettingGet(ModID.."Mama")) then
				GamePrint("Happy Birthday! "..t[m][d])
				ModSettingSet(ModID.."Mama", true)
            elseif t[m][d] == nil and ModSettingGet(ModID.."Mama") then
				ModSettingSet(ModID.."Mama", false)
			end
			if UI.GetPickerStatus("UnlimitedSpells") and not GameHasFlagRun("WandEditorUnlimitedSpells") then--无限法术切换
                local player = GetPlayer()
                local world_entity_id = GameGetWorldStateEntity()
                if world_entity_id ~= nil then
                    local comp_worldstate = EntityGetFirstComponent(world_entity_id, "WorldStateComponent")
                    if comp_worldstate ~= nil then
                        ComponentSetValue2(comp_worldstate, "perk_infinite_spells", true)
                    end
                end
                GameRegenItemActionsInPlayer(player)
                UI.OnceCallOnExecute(function()
                    RefreshHeldWands()
                end)
                GameAddFlagRun("WandEditorUnlimitedSpells")
            elseif not UI.GetPickerStatus("UnlimitedSpells") and GameHasFlagRun("WandEditorUnlimitedSpells") then
				local world_entity_id = GameGetWorldStateEntity()
                if world_entity_id ~= nil then
                    local comp_worldstate = EntityGetFirstComponent(world_entity_id, "WorldStateComponent")
                    if comp_worldstate ~= nil then
                        ComponentSetValue2(comp_worldstate, "perk_infinite_spells", false)
                    end
                end
				UI.OnceCallOnExecute(function()
                    RefreshHeldWands()
                end)
				GameRemoveFlagRun("WandEditorUnlimitedSpells")
			end
			if UI.GetPickerStatus("InfFly") and not GameHasFlagRun("WandEditorInfFly") then
                local player = GetPlayer()
                local CharacterComp = EntityGetFirstComponent(player, "CharacterDataComponent")
				if CharacterComp then
                    ComponentSetValue2(CharacterComp, "flying_needs_recharge", false)
					GameAddFlagRun("WandEditorInfFly")
				end
            elseif not UI.GetPickerStatus("InfFly") and GameHasFlagRun("WandEditorInfFly") then
				local player = GetPlayer()
                local CharacterComp = EntityGetFirstComponent(player, "CharacterDataComponent")
				if CharacterComp then
                    ComponentSetValue2(CharacterComp, "flying_needs_recharge", true)
					GameRemoveFlagRun("WandEditorInfFly")
				end
			end
            if UI.GetPickerStatus("LockHP") then--血量锁定实现
                local player = GetPlayer()
				local damage_model = EntityGetFirstComponent( player, "DamageModelComponent" )
                if UI.UserData["LockHPValue"] == nil and damage_model then
                    local hp = ComponentGetValue2(damage_model, "hp")
                    UI.UserData["LockHPValue"] = hp
                elseif UI.UserData["LockHPValue"] and damage_model then
                    ComponentSetValue2(damage_model, "hp", UI.UserData["LockHPValue"])
                end
            else
				UI.UserData["LockHPValue"] = nil
			end
			if GameIsInventoryOpen() then--开启开启物品栏时禁止执行下一步
				return
			end
			
            if UI.GetPickerStatus("QuickTP") and EntityGetWithName("advanced_map") == 0 and not SkipDisableThrow then
                local player = GetPlayer()
                local Active = GetActiveItem()
                if Active ~= nil then
                    local ItemAbility = EntityGetFirstComponentIncludingDisabled(Active, "AbilityComponent")
                    if ItemAbility ~= nil then
                        local HasData, comp = GetStorageComp(Active, "wand_editor_get_throw")
                        if comp == nil then
                            local throw = ComponentGetValue2(ItemAbility, "throw_as_item")
                            local throwInt
                            if throw then
                                throwInt = 1
                            else
                                throwInt = 0
                            end
                            AddSetStorageComp(Active, "wand_editor_get_throw", throwInt)
                            ComponentSetValue2(ItemAbility, "throw_as_item", false)
                        end
                    end
                end

                local Controls = EntityGetFirstComponent(player, "ControlsComponent")
                local right = ComponentGetValue2(Controls, "mButtonDownThrow")
                if right and (UI.UserData["QuickTPFr"] == nil or UI.UserData["QuickTPFr"] == 0) then
                    local x, y = DEBUG_GetMouseWorld()
                    EntitySetTransform(player, x, y)
                    if UI.UserData["QuickTPFr"] ~= 0 then
                        UI.UserData["QuickTPFr"] = 20
                    end
                elseif right and UI.UserData["QuickTPFr"] and UI.UserData["QuickTPFr"] ~= 0 then
                    UI.UserData["QuickTPFr"] = UI.UserData["QuickTPFr"] - 1
                elseif not right and UI.UserData["QuickTPFr"] then
                    UI.UserData["QuickTPFr"] = nil
                end
            end
			if UI.GetPickerStatus("DisablePlayerGravity") and not GameHasFlagRun("wand_editor_disable_player_gravity") then
                local player = GetPlayer()
                local comp = EntityGetFirstComponentIncludingDisabled(player, "CharacterPlatformingComponent")
                if comp ~= nil then
                    local x_min = ComponentGetValue2(comp, "velocity_min_x")
                    local x_max = ComponentGetValue2(comp, "velocity_max_x")
                    local y_min = ComponentGetValue2(comp, "velocity_min_y")
					local y_max = ComponentGetValue2(comp, "velocity_max_y")
                    ModSettingSet(ModID .. "player_gra_x_min", x_min)
                    ModSettingSet(ModID .. "player_gra_x_max", x_max)
					ModSettingSet(ModID .. "player_gra_y_min", y_min)
                    ModSettingSet(ModID .. "player_gra_y_max", y_max)
                    ComponentSetValue2(comp, "velocity_min_x", 0)
                    ComponentSetValue2(comp, "velocity_max_x", 0)
					ComponentSetValue2(comp, "velocity_min_y", 0)
					ComponentSetValue2(comp, "velocity_max_y", 0)
				end
                GameAddFlagRun("wand_editor_disable_player_gravity")
            elseif not UI.GetPickerStatus("DisablePlayerGravity") and GameHasFlagRun("wand_editor_disable_player_gravity") then
				local player = GetPlayer()
                local comp = EntityGetFirstComponentIncludingDisabled(player, "CharacterPlatformingComponent")
				if comp ~= nil then
					local x_min = ModSettingGet(ModID .. "player_gra_x_min") or 0
					local x_max = ModSettingGet(ModID .. "player_gra_x_max") or 0
					local y_min = ModSettingGet(ModID .. "player_gra_y_min") or 0
                    local y_max = ModSettingGet(ModID .. "player_gra_y_max") or 0
					ComponentSetValue2(comp, "velocity_min_x", x_min)
                    ComponentSetValue2(comp, "velocity_max_x", x_max)
					ComponentSetValue2(comp, "velocity_min_y", y_min)
					ComponentSetValue2(comp, "velocity_max_y", y_max)
				end
				GameRemoveFlagRun("wand_editor_disable_player_gravity")
			end
            if GameIsInventoryOpen() or (not UI.GetPickerStatus("MainButton")) then --主按钮关闭时禁止下一步
                return
            end

            if UI.GetPickerStatus("DamageInfo") then
                DrawDamageInfo()
            end
			if not UI.GetPickerStatus("SpellDepotBTN") and UI.GetPickerStatus("AlwaysDrawWandEditBox") and UI.GetPickerStatus("WandContainerBTN") then
				DrawWandContainer(UI, Compose(GetEntityHeldWand, GetPlayer)(), spellData)
			end
		end
	end

	UI.DispatchMessage()
end

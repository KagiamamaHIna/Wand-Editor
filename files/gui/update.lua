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
		UI.PickerEnableList("WandBuilderBTN", "SpellDepotBTN", "WandDepotBTN")
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

			local function WandDepotCB(_, _, _, _, this_enable)
                if not this_enable then
                    return
                end
				
			end

			UI.MoveImagePicker("WandDepotBTN", PickerGap(2), y + 30, 8, 0, GameTextGet("$wand_editor_wand_depot"),
				"mods/wand_editor/files/gui/images/wand_depot.png", nil, nil, nil, true, nil,
				true)
			
		end
		---@param this Gui
		UI.TickEventFn["main"] = function(this)--我认为的主事件循环）
            if not GameIsInventoryOpen() and GetPlayer() then
				GuiOptionsAdd(UI.gui, GUI_OPTION.NoPositionTween) --你不要再飞啦！

                GuiZSetForNextWidget(this.gui, UI.GetZDeep()) --设置深度，确保行为正确
                UI.MoveImagePicker("MainButton", 185, 12, 8, 0, GameTextGet("$wand_editor_main_button"),
                    "mods/wand_editor/files/gui/images/menu.png", nil, MainCB, nil, false, nil, true)
            end
			
		end
	end

	UI.DispatchMessage()
end

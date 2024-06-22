local UI
function GUIUpdata()
	if UI == nil then
        --初始化
		---@class Gui
		UI = dofile_once("mods/wand_editor/files/libs/gui.lua")
		dofile_once("mods/wand_editor/files/libs/fn.lua")
		dofile_once("data/scripts/lib/utilities.lua")
        dofile_once("mods/wand_editor/files/gui/SpellsScroll.lua")
        dofile_once("mods/wand_editor/files/gui/WandContainer.lua")
		UI.UserData["HasSpellMove"] = false
		local data = dofile_once("mods/wand_editor/files/gui/GetSpellData.lua")--读取法术数据
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
				UI.TickEventFn["MoveSpellFn"] = function() --分离出一个事件，用于表示法术点击后的效果
                    local click = InputIsMouseButtonDown(Mouse_right)
                    if click or GameIsInventoryOpen() then --右键取消，或打开物品栏取消
						if GameIsInventoryOpen() and UI.UserData["UpSpellIndex"] then--如果是点击之前的法术并且打开了物品栏，恢复法术
							SetTableSpells(UI.UserData["UpSpellIndex"][2], UI.UserData["FloatSpellID"], UI.UserData["UpSpellIndex"][1], UI.UserData["UpSpellIndex"][4], false)
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
					local status = UI.OnMoveImage("MoveSpell", x, y, sprite, nil, nil, ZDeepest-114514, UI.UserData["SpellHoverEnable"],
						function(movex, movey)
							GuiZSetForNextWidget(UI.gui, ZDeepest-114513)
							GuiImage(UI.gui, UI.NewID("MoveSpell_BG"), movex - 2, movey - 2, SpellTypeBG[spellData[id].type], 1, 1) --绘制背景
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
		--获得玩家当前法杖数据
        local GetPlayerWandID = Compose(GetEntityHeldWand, GetPlayer)
        local GetPlayerXY = Compose(EntityGetTransform, GetPlayer)
		
        local MainButtonEnable = nil
        local SpellDrawType = "AllSpells"
        local TypeList = {
			"AllSpells",
			ACTION_TYPE_PROJECTILE,
			ACTION_TYPE_STATIC_PROJECTILE,
			ACTION_TYPE_MODIFIER,
			ACTION_TYPE_DRAW_MANY,
			ACTION_TYPE_MATERIAL,
			ACTION_TYPE_OTHER,
			ACTION_TYPE_UTILITY,
            ACTION_TYPE_PASSIVE,
            "favorite"
		}
        local SpellList = {
            AllSpells = "AllSpells",
            [ACTION_TYPE_PROJECTILE] = "projectile",
            [ACTION_TYPE_STATIC_PROJECTILE] = "static_projectile",
            [ACTION_TYPE_MODIFIER] = "modifier",
            [ACTION_TYPE_DRAW_MANY] = "draw_many",
            [ACTION_TYPE_MATERIAL] = "material",
            [ACTION_TYPE_OTHER] = "other",
            [ACTION_TYPE_UTILITY] = "utility",
            [ACTION_TYPE_PASSIVE] = "passive",
        }
		local CurrentBtn = nil
        UI.PickerEnableList("WandBuilderBTN", "SpellDepotBTN")
		UI.SetCheckboxEnable("shuffle_builder", false)
		---@param this Gui
        UI.TickEventFn["main"] = function(this)
			if not GameIsInventoryOpen() and GetPlayer() then
                GuiOptionsAdd(this.gui, GUI_OPTION.NoPositionTween) --你不要再飞啦！
				GuiZSetForNextWidget(this.gui, UI.GetZDeep())--设置深度，确保行为正确
				UI.MoveImagePicker("MainButton", 185, 12, 8, 0, GameTextGetTranslatedOrNot("$wand_editor_main_button"), "mods/wand_editor/files/gui/images/menu.png",
					function(x, y)
						if MainButtonEnable then

						end
					end,
					function(left_click, right_click, x, y, enable)
						MainButtonEnable = enable
                        if left_click then
                            --local wandData = GetPlayerHeldWandData()
							--InitWand(wandData, nil, GetPlayerXY())
							--[[
                            local x, y = EntityGetTransform(GetPlayer())
                            local e = InitWand(GetWandData(GetEntityHeldWand(GetPlayer())), nil, x, y)]]
						end
                        if enable then --开启状态
                            local function SpellDepotClickCB(_, _, _, _, depot_enable)
                                if not depot_enable then
                                    return
                                end
                                CurrentBtn = Default(CurrentBtn, "SpellDepotBTN")
                                local function HelpHover()
                                    UI.tooltips(function()
                                        GuiText(this.gui, 0, 0, GameTextGetTranslatedOrNot("$wand_editor_search_help"))
                                    end, nil, 5)
                                end
                                this.MoveImageButton("SpellDepotHelp", 200, 249,
                                    "mods/wand_editor/files/gui/images/help.png", nil, HelpHover, nil, nil, true)

                                local function WandContainerClickCB(_, _, _, _, WandContainer_enable)
                                    if WandContainer_enable then
                                        DrawWandContainer(this, GetPlayerWandID(), spellData)
                                    end
                                end
                                UI.MoveImagePicker("WandContainerBTN", 28, 247, 8, 20,
                                    GameTextGet("$wand_editor_wand_edit_box"),
                                    "mods/wand_editor/files/gui/images/wand_container.png", nil, WandContainerClickCB,
                                    nil, true, nil, true)

                                local DrawSpellList, InputType = SearchSpell(this, spellData, TypeToSpellList,
                                    SpellDrawType)
                                --绘制容器
                                DrawSpellContainer(this, spellData, DrawSpellList, InputType)
                                for i, v in pairs(TypeList) do --绘制左边选择类型按钮
                                    local sprite
                                    if v == "AllSpells" then
                                        sprite = ModDir .. "files/gui/images/all_spells.png"
                                    elseif v == "favorite" then
                                        sprite = ModDir .. "files/gui/images/favorite_icon.png"
                                    else
                                        sprite = ModDir .. "files/gui/images/" .. SpellList[v] .. "_icon.png"
                                    end

                                    local Hover = function()
                                        local _, _, hover = GuiGetPreviousWidgetInfo(this.gui)
                                        if hover then
                                            SpellDrawType = v
                                            local HoverText
                                            if v == "AllSpells" then
                                                HoverText = GameTextGetTranslatedOrNot("$wand_editor_All_spells")
                                            elseif v == "favorite" then
                                                HoverText = GameTextGetTranslatedOrNot("$wand_editor_favorite")
                                            else
                                                HoverText = SpellTypeEnumToStr(v)
                                            end
                                            this.tooltips(function()
                                                GuiText(this.gui, 0, 0, HoverText)
                                            end, ZDeepest - 1145, nil, nil, true)
                                        end
                                    end
                                    if SpellDrawType ~= v then
                                        GuiOptionsAddForNextWidget(this.gui, GUI_OPTION.DrawSemiTransparent)
                                    end
                                    this.MoveImageButton("Switch" .. v, 7, 44 + i * 20, sprite, nil, Hover, nil, nil,
                                        true)
                                end
                            end

							UI.MoveImagePicker("SpellDepotBTN",19,y+30,8,0,GameTextGet("$wand_editor_spell_depot"),"mods/wand_editor/files/gui/images/spell_depot.png",nil,SpellDepotClickCB,nil,true,nil,true)
                            local function WandBuilderCB(_, _, _, _, this_enable)
                                if not this_enable then
                                    return
                                end
								local BuilderH = 140
                                UI.ScrollContainer("WandBuilder", 20, 64, 180, BuilderH, 2, 2)
								UI.AddAnywhereItem("WandBuilder", function ()
                                    local leftMargin = 60
                                    local function NewLine(str, ShowText, fn)
										str = GameTextGetTranslatedOrNot(str)
                                        GuiLayoutBeginHorizontal(this.gui, 0, 0, true, 2, -1)
                                        local w = GuiGetTextDimensions(this.gui, str)
                                        GuiText(this.gui, leftMargin - w, 0, str)
                                        local ShowW = GuiGetTextDimensions(this.gui, ShowText)
										GuiRGBAColorSetForNextWidget(this.gui, 210, 180, 140, 255)
										GuiText(this.gui, 5, 0, ShowText)
										fn()
                                        GuiLayoutEnd(this.gui)
                                    end
                                    GuiLayoutBeginVertical(this.gui, 0, 0, true)
									local shuffle
									if UI.GetCheckboxEnable("shuffle_builder") then
										shuffle = GameTextGet("$menu_yes")
									else
										shuffle = GameTextGet("$menu_no")
									end
									NewLine("$inventory_shuffle",shuffle,function ()
										UI.checkbox("shuffle_builder", 2, 1, "", nil, nil, nil, nil)
                                    end)
									
									GuiLayoutEnd(this.gui)
								end)
								UI.DrawScrollContainer("WandBuilder")
                            end

                            UI.MoveImagePicker("WandBuilderBTN", 39, y + 30, 8, 0, "法杖生成器","mods/wand_editor/files/gui/images/wand_builder.png", nil, WandBuilderCB, nil, true, nil, true)
						end

                    end,nil,false,nil,true)
			end
		end
	end

	UI.DispatchMessage()
end

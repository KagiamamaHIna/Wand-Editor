local UI
function GUIUpdata()
	if UI == nil then
		--初始化
		UI = dofile_once("mods/wand_editor/files/libs/gui.lua")
		dofile_once("mods/wand_editor/files/libs/fn.lua")
		dofile_once("data/scripts/lib/utilities.lua")
		dofile_once("mods/wand_editor/files/gui/SpellsScroll.lua")
		local data = dofile_once("mods/wand_editor/files/gui/GetSpellData.lua")--读取法术数据
		local spellData = data[1]
		local TypeToSpellList = data[2]

		--获得玩家当前法杖数据
        local GetPlayerHeldWandData = Compose(GetWandData, GetEntityHeldWand, GetPlayer)
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
		UI.TickEventFn["main"] = function(this)
			if not GameIsInventoryOpen() then
                GuiOptionsAdd(this.gui, GUI_OPTION.NoPositionTween) --你不要再飞啦！
				local ZDeepest = this.GetZDeep()
				GuiZSetForNextWidget(this.gui, UI.GetZDeep())--设置深度，确保行为正确
				UI.MoveImagePicker("MainButton", 40, 50, 8, 0, GameTextGetTranslatedOrNot("$wand_editor_main_button"), "mods/wand_editor/files/gui/images/menu.png",
					function(x, y)
						if MainButtonEnable then

						end
					end,
					function(left_click, right_click, x, y, enable)
						MainButtonEnable = enable
                        if left_click then
							OnMoveImage = not OnMoveImage
                            --local wandData = GetPlayerHeldWandData()
							--InitWand(wandData, nil, GetPlayerXY())
							--[[
                            local x, y = EntityGetTransform(GetPlayer())
                            local e = InitWand(GetWandData(GetEntityHeldWand(GetPlayer())), nil, x, y)]]
						end
                        if enable then --开启状态
							local function HelpHover()
								UI.tooltips(function ()
									GuiText(this.gui,0,0,GameTextGetTranslatedOrNot("$wand_editor_search_help"))
								end,nil,5)
							end
							this.MoveImageButton("SpellBagHelp", 200, 245, "mods/wand_editor/files/gui/images/help.png", nil, HelpHover, nil, nil, true)
                            local DrawSpellList = SearchSpell(this, spellData, TypeToSpellList, SpellDrawType)
							--绘制容器
                            DrawSpellContainer(this, spellData, DrawSpellList, SpellDrawType)

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
                                        end, ZDeepest - 2, nil, nil, true)
                                    end
                                end
                                if SpellDrawType ~= v then
                                    GuiOptionsAddForNextWidget(this.gui, GUI_OPTION.DrawSemiTransparent)
                                end
                                this.MoveImageButton("Switch" .. v, 7, 40 + i * 20, sprite, nil, Hover, nil, nil, true)
                            end
							
						end
                        if OnMoveImage then
                            --[[
						local status,x,y = UI.OnMoveImage("Test",0,0,"mods/wand_editor/files/gui/images/menu.png")
						if not status then
							OnMoveImage = false
							print(x,y)
						end]]
                        end
                    end)
			end
		end
	end

	UI.DispatchMessage()
end

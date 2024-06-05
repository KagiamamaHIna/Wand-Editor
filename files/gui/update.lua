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

		local OnMoveImage = false
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
			ACTION_TYPE_PASSIVE
		}
        local SpellList = {
            AllSpells = "AllSpells",
            [ACTION_TYPE_PROJECTILE] = "projectile",
            [ACTION_TYPE_STATIC_PROJECTILE] = "static_projectile",
            [ACTION_TYPE_MODIFIER] = "modifier",
            [ACTION_TYPE_DRAW_MANY] = "draw_many",
            [ACTION_TYPE_MATERIAL] = "material",
            [ACTION_TYPE_OTHER] = "utility",
            [ACTION_TYPE_UTILITY] = "other",
            [ACTION_TYPE_PASSIVE] = "passive",
        }
        local LastSearch = ""
		local LastList
		UI.TickEventFn["main"] = function(this)
			if not GameIsInventoryOpen() then
                GuiOptionsAdd(this.gui, GUI_OPTION.NoPositionTween) --你不要再飞啦！
				GuiZSetForNextWidget(this.gui, UI.GetZDeep())--设置深度，确保行为正确
				UI.MoveImagePicker("MainButton", 40, 50, 8, 0, "法杖编辑器", "mods/wand_editor/files/gui/images/menu.png",
					function(x, y)
						if MainButtonEnable then

						end
					end,
					function(left_click, right_click, x, y, enable)
						MainButtonEnable = enable
                        if left_click then
							OnMoveImage = not OnMoveImage
							
							--[[
                            local x, y = EntityGetTransform(GetPlayer())
                            local e = InitWand(GetWandData(GetEntityHeldWand(GetPlayer())), nil, x, y)]]
						end
                        if enable then --开启状态
                            local Search = UI.TextInput("input", 63, 245, 120, 80)
							local DrawSpellList = TypeToSpellList[SpellDrawType]
                            if Search ~= "" and LastSearch ~= Search then
								LastSearch = Search
                                local ScoreToSpellID = {}
                                local ScoreList = {}
								local HasScore = {}
                                for _, v in pairs(DrawSpellList) do
                                    local score = Cpp.PinyinRatio(GameTextGetTranslatedOrNot(spellData[v].name), Search)
                                    if ScoreToSpellID[score] == nil then
                                        ScoreToSpellID[score] = {}
                                    end
                                    table.insert(ScoreToSpellID[score], v)
									if HasScore[score] == nil then
                                        table.insert(ScoreList, score)
										HasScore[score] = true
									end
                                end
                                table.sort(ScoreList)
								DrawSpellList = {}
                                for i = #ScoreList, 1, -1 do
                                    if ScoreList[i] > 60 then--匹配度超过60就进入结果中
                                        for _, v in pairs(ScoreToSpellID[ScoreList[i]]) do
                                            table.insert(DrawSpellList, v)
                                        end
                                    else
										break
									end
                                end
								LastList = DrawSpellList
                            elseif LastSearch == Search and Search ~= "" then
								DrawSpellList = LastList
							end
							--绘制容器
                            DrawSpellContainer(this, spellData, DrawSpellList, SpellDrawType)
							for i,v in pairs(TypeList)do
								local sprite
								if v ~= "AllSpells" then
                                    sprite = ModDir .. "files/gui/images/" .. SpellList[v] .. "_icon.png"
                                else
									sprite = ModDir .. "files/gui/images/all_spells.png"
								end
								
                                local Hover = function()
                                    local _, _, hover = GuiGetPreviousWidgetInfo(this.gui)
                                    if hover then
                                        SpellDrawType = v
                                    end
                                end
								if SpellDrawType ~= v then
									GuiOptionsAddForNextWidget( this.gui, GUI_OPTION.DrawSemiTransparent )
								end
								this.MoveImageButton("Switch"..v, 7, 40 + i*20, sprite, nil, Hover, nil, nil, true)
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

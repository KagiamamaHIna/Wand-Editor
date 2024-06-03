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
		local typelist = data[2]

		--获得玩家当前法杖数据
        local GetPlayerHeldWandData = Compose(GetWandData, GetEntityHeldWand, GetPlayer)

		local OnMoveImage = false
		local MainButtonEnable = nil
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
							--绘制容器
							DrawSpellContainer(this, spellData, typelist[ACTION_TYPE_PROJECTILE])
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

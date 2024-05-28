local UI
function GUIUpdata()
	if UI == nil then
		--初始化
		UI = dofile_once("mods/wand_editor/files/libs/gui.lua")
		dofile_once("mods/wand_editor/files/libs/fn.lua")
        dofile_once("data/scripts/lib/utilities.lua")
		
		local data = dofile_once("mods/wand_editor/files/gui/GetSpellData.lua")
        local function DarwSpellsScroll()

        end

		--获得玩家当前法杖数据
		local GetPlayerHeldWandData = Compose(GetWandData, GetEntityHeldWand, GetPlayer)

		local OnMoveImage = false
		local MainButtonEnable = nil
		UI.TickEventFn["main"] = function(this)
			if not GameIsInventoryOpen() then
				GuiOptionsAdd(this.gui, GUI_OPTION.NoPositionTween) --你不要再飞啦！
				UI.MoveImagePicker("MainButton", 40, 50, "世界编辑工具", "mods/wand_editor/files/gui/images/menu.png",
					function(x, y)
						if MainButtonEnable then
							
							UI.MoveImagePicker("MainButton2", x + 30, y, "测试文本1",
								"mods/wand_editor/files/gui/images/menu.png", nil, nil, nil, true)
							UI.MoveImagePicker("MainButton3", x + 60, y, "测试文本2",
								"mods/wand_editor/files/gui/images/menu.png", nil, nil, nil, true)
							UI.MoveImagePicker("MainButton4", x + 90, y, "测试文本3",
								"mods/wand_editor/files/gui/images/menu.png", nil, nil, nil, true)
						end
					end,
                    function(left_click, right_click, x, y, enable)
						MainButtonEnable = enable
                        if left_click then
                            local x, y = EntityGetTransform(GetPlayer())
                            local e = InitWand(GetWandData(GetEntityHeldWand(GetPlayer())), nil, x, y)
                            --EntityLoad("mods/wand_editor/files/entity/RemoveMaterial.xml",x,y)
                            --TablePrint(data.ICEBALL)
                        end
                        if enable then --开启状态

						end
						if OnMoveImage then
							--[[
						local status,x,y = UI.OnMoveImage("Test",ButtonX,ButtonY,"mods/wand_editor/files/gui/images/menu.png")
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

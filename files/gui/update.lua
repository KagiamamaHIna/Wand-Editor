function GUIUpdata()
	if UI == nil then
		--初始化
		if not ModIsEnabled("wand_editor") then --先确定是否启用模组
			EntityKill(GetUpdatedEntityID())
		end
		UI = dofile_once("mods/wand_editor/files/libs/gui.lua")
		dofile_once("mods/wand_editor/files/libs/fn.lua")
		dofile_once("data/scripts/lib/utilities.lua")

		local function DarwSpellsScroll()

		end

		--获得玩家当前法杖数据
		local GetPlayerHeldWandData = Compose(GetWandData, GetEntityHeldWand, GetPlayer)

		local OnMoveImage = false
		local ButtonX = 0
		local ButtonY = 0

		UI.TickEventFn["main"] = function(this)
			if not GameIsInventoryOpen() then
				GuiOptionsAdd(this.gui, GUI_OPTION.NoPositionTween) --你不要再飞啦！
				UI.MoveImagePicker("MainButton", 40, 50, "世界编辑工具", "mods/wand_editor/files/gui/images/menu.png",
					function(x, y)
						ButtonX = x
						ButtonY = y
					end,
                    function(left_click, right_click, x, y, enable)
                        if left_click then
							local x,y = EntityGetTransform(GetPlayer())
                            local e = InitWand(GetWandData(GetEntityHeldWand(GetPlayer())),nil,x,y)
						end
                        if enable then --开启状态

							UI.MoveImagePicker("MainButton2", x + 30, y, "测试文本1",
								"mods/wand_editor/files/gui/images/menu.png", nil, nil, nil, true)
							UI.MoveImagePicker("MainButton3", x + 60, y, "测试文本2",
								"mods/wand_editor/files/gui/images/menu.png", nil, nil, nil, true)
							UI.MoveImagePicker("MainButton4", x + 90, y, "测试文本3",
								"mods/wand_editor/files/gui/images/menu.png", nil, nil, nil, true)
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

function GUIUpdata()
	if UI == nil then
		--初始化
		if not ModIsEnabled("wand_editor") then --先确定是否启用模组
			EntityKill(GetUpdatedEntityID())
		end
		UI = dofile_once("mods/world_editor/files/libs/gui.lua")
		dofile_once("mods/world_editor/files/libs/fn.lua")
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
				--[[
				local status = this.ImageButtonCanMove(UI.NewID("MainButton"),"mods/world_editor/files/gui/images/menu.png",40,50,nil,nil,function ()
					UI.tooltips(function()
						GuiText( this.gui, 0, 0, tipsTextTable[MainButtonStatus] );
					end, -100, 12, 6 );
				end)
				GuiImage(this.gui,UI.NewID("TEST"),40,60,"mods/world_editor/files/gui/images/pixel.png",1,12)
				if status then--为真时就代表点了一下
					MainButtonStatus = not MainButtonStatus
				end
				---print(this.ScreenWidth,this.ScreenHeight)
				if MainButtonStatus then

	
					local wandData = GetPlayerHeldWandData()
					TablePrint(wandData)
					--print("-----------------")
				else
					
				end]]
				GuiOptionsAdd(this.gui, GUI_OPTION.NoPositionTween) --你不要再飞啦！
				UI.MoveImagePicker("MainButton", 40, 50, "世界编辑工具", "mods/world_editor/files/gui/images/menu.png",
					function(x, y)
						ButtonX = x
						ButtonY = y
					end,
                    function(left_click, right_click, x, y, enable)
                        if left_click then
							                            --[[
                            local t = GetEntityAllData(GetEntityHeldWand(GetPlayer()))
							TablePrint(t)]]
                            local t = GetWandData(GetEntityHeldWand(GetPlayer()))
							local x, y = EntityGetTransform(GetPlayer())
							InitWand(t,nil,x,y)
							TablePrint(t)
						end
                        if enable then --开启状态

							UI.MoveImagePicker("MainButton2", x + 30, y, "测试文本1",
								"mods/world_editor/files/gui/images/menu.png", nil, nil, nil, true)
							UI.MoveImagePicker("MainButton3", x + 60, y, "测试文本2",
								"mods/world_editor/files/gui/images/menu.png", nil, nil, nil, true)
							UI.MoveImagePicker("MainButton4", x + 90, y, "测试文本3",
								"mods/world_editor/files/gui/images/menu.png", nil, nil, nil, true)
						end
						if OnMoveImage then
							--[[
						local status,x,y = UI.OnMoveImage("Test",ButtonX,ButtonY,"mods/world_editor/files/gui/images/menu.png")
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

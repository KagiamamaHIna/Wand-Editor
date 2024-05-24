function GUIUpdata()
	if UI == nil then
		--初始化
		if not ModIsEnabled("wand_editor") then--先确定是否启用模组
			EntityKill(GetUpdatedEntityID())
		end
		UI = dofile_once("mods/world_editor/files/libs/gui.lua")
		dofile_once("mods/world_editor/files/libs/fn.lua")
		dofile_once( "data/scripts/lib/utilities.lua" )
	
		local function DarwSpellsScroll()
			
		end
	
		--获得玩家当前法杖数据
		local GetPlayerHeldWandData = Compose(GetWandData,GetEntityHeldWand,GetPlayer)
	
		local MainButtonStatus = false
		local OnMoveImage = false
		local ButtonX = 0
		local ButtonY = 0
		local tipsTextTable = {}
		tipsTextTable[false] = "这是测试文本，现在该按钮未被点击"
		tipsTextTable[true] = "点了一下！，再点击变回原文本"
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

				UI.MoveImageButton("MainButton",40,50,"mods/world_editor/files/gui/images/menu.png",
				function (x,y)
					ButtonX = x
					ButtonY = y
				end,
				function ()
					UI.tooltips(function()
						GuiText( this.gui, 0, 0, tipsTextTable[MainButtonStatus] );
						GuiText(this.gui, 0, 0,"按住shift+鼠标左键可以移动按钮，再按一次鼠标左键确定位置")
						GuiText(this.gui, 0, 0,"按鼠标右键重置位置到原位")
					end, -100, 12, 6 );	
				end,
				function (left_click,right_click)
					if left_click then--为真时就代表点了一下
						MainButtonStatus = not MainButtonStatus
						OnMoveImage = not OnMoveImage
					end
					if MainButtonStatus then
					else
						
					end
					if OnMoveImage then
						local status,x,y = UI.OnMoveImage("Test",ButtonX,ButtonY,"mods/world_editor/files/gui/images/menu.png")
						if not status then
							OnMoveImage = false
							print(x,y)
						end
					end
				end)
			end
		end
	end
	
	UI.DispatchMessage()
	
end

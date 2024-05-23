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
		local tipsTextTable = {}
		tipsTextTable[false] = "开启法杖编辑器"
		tipsTextTable[true] = "关闭法杖编辑器"
		UI.TickEventFn["main"] = function(this)
			if not GameIsInventoryOpen() then
				GuiOptionsAdd(this.gui, GUI_OPTION.NoPositionTween);
				local status = this.ImageButtonCanMove(UI.NewID("MainButton"),"mods/world_editor/files/gui/images/menu.png",40,40,nil,nil,function ()
					UI.tooltips(function()
						GuiText( this.gui, 0, 0, tipsTextTable[MainButtonStatus] );
					end, -100, 12, 6 );
				end)--22,5
	
				if status then--为真时就代表点了一下
					MainButtonStatus = not MainButtonStatus
				end
				---print(this.ScreenWidth,this.ScreenHeight)
				if MainButtonStatus then
					--GuiButton( this.gui, this.NewID("button2"), 2, 13, "test" )
					--GuiImageButton(this.gui,UI.NewID("test"),44,5,"","mods/world_editor/files/gui/images/menu.png")
					--绘制窗口
					--[[
					GuiLayoutBeginVertical( this.gui, 2, 13 )
					GuiText( this.gui, 0, 0, "== DEBUG MENU ==" )
					GuiLayoutEnd( this.gui )
					local spells = GetWandSpellIDs(GetPlayerHeldWand())
					for _,v in pairs(spells)do
						print(v)
					end
					]]
	
					local wandData = GetPlayerHeldWandData()
					TablePrint(wandData)
					--print("-----------------")
				else
					
				end
			end
		end
	end
	
	UI.DispatchMessage()
	
end

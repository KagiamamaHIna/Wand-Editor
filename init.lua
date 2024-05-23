dofile_once("mods/world_editor/files/libs/unsafe.lua")
dofile_once("mods/world_editor/files/gui/update.lua")
dofile_once( "data/scripts/lib/utilities.lua" );
--[[
function OnWorldPreUpdate()
    dofile( "data/entities/_debug/debug_menu.lua" );
end]]
local gui = GuiCreate()
function  OnPlayerSpawned(player)
    --EntityLoadChild(player,"data/entities/_debug/debug_menu.xml")
    if not GameHasFlagRun("world_editor_init") then
        GameAddFlagRun("world_editor_init")
    end
end


function OnWorldPostUpdate()
	GUIUpdata()
end

--[[
function OnWorldPreUpdate()
    GuiStartFrame(gui)
    GuiImageButton(gui,123,114,45,"","mods/world_editor/files/gui/images/menu.png")

    if z == nil then z = -12; end
    local left_click,right_click,hover,x,y,width,height,draw_x,draw_y,draw_width,draw_height = GuiGetPreviousWidgetInfo( gui );
    if x_offset == nil then x_offset = 0; end
    if y_offset == nil then y_offset = 0; end
    if hover then
        GuiZSet( gui, z );
        GuiLayoutBeginLayer( gui );
            GuiLayoutBeginVertical( gui, ( x + x_offset + width ), ( y + y_offset ), true );
                GuiBeginAutoBox( gui );

                    GuiText(gui,0,0,"114514")
                    GuiZSetForNextWidget( gui, z + 1 );
                GuiEndAutoBoxNinePiece( gui );
            GuiLayoutEnd( gui );
        GuiLayoutEndLayer( gui );
    end
end]]

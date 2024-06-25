local function DrawWandSlot(id, k, wand)
	GuiImage(UI.gui,UI.NewID(id..tostring(k)),0, 0,wand.sprite_file,1,1,0,math.rad(-57.5))
end

function WandDepotCB(_, _, _, _, this_enable)
	if not this_enable then
		return
	end
	
end

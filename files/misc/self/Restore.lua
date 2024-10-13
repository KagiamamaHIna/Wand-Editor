if not ModIsEnabled("wand_editor") then
    dofile_once("mods/wand_editor/files/libs/fn.lua")
    RestoreInput() --恢复可能的按键操作
    local player = GetUpdatedEntityID()
	if GlobalsGetValue(ModID.."CameraLocked") == "1" then
		local PSPComp = EntityGetFirstComponentIncludingDisabled(player, "PlatformShooterPlayerComponent")
		if PSPComp then
			local center_camera_on_this_entity = ComponentGetValue2(PSPComp, "center_camera_on_this_entity")
			if not center_camera_on_this_entity then
				ComponentSetValue2(PSPComp, "center_camera_on_this_entity", true)
			end
		end
	end
end

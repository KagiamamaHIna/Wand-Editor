dofile_once("mods/wand_editor/files/misc/bygoki/lib/helper.lua")
local Nxml = dofile_once("mods/wand_editor/files/libs/nxml.lua")

local old_thousands_separator = thousands_separator
local thousands_separator = function(num)
	if num > 1e15 then
		return string.lower(tostring(num))
	else
		return old_thousands_separator(string.format("%.2f", num))
	end
end

local function get_screen_position(x, y)
	local screen_width, screen_height = GuiGetScreenDimensions(UI.gui)
	local camera_x, camera_y = GameGetCameraPos()
	local res_width = MagicNumbersGetValue("VIRTUAL_RESOLUTION_X")
	local res_height = MagicNumbersGetValue("VIRTUAL_RESOLUTION_Y")
	local ax = (x - camera_x) / res_width * screen_width
	local ay = (y - camera_y) / res_height * screen_height
	return ax + screen_width * 0.5, ay + screen_height * 0.5
end

function DrawDamageInfo()
	GuiLayoutBeginLayer(UI.gui)
	GuiLayoutBeginVertical(UI.gui, UI.ScreenWidth * 0.5, 0, true)
	GuiLayoutAddVerticalSpacing(UI.gui, 5)

	local player_projectiles = EntityGetWithTag("projectile_player") or {}
	local highest_projectile_damage = 0
	local highest_damage_projectile = nil
	local total_projectile_damage = 0
	local total_projectiles = #player_projectiles
	for k, v in pairs(player_projectiles) do
		local projectile = EntityGetFirstComponent(v, "ProjectileComponent")
		if projectile then
			local damage = ComponentGetValue2(projectile, "damage") * 25
			if damage > highest_projectile_damage then
				highest_damage_projectile = v
				highest_projectile_damage = damage
			end
			total_projectile_damage = total_projectile_damage + damage
		end
	end
	GuiOptionsAddForNextWidget(UI.gui, GUI_OPTION.Align_HorizontalCenter)
	GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_total_proj_dmg") .. thousands_separator(total_projectile_damage))

	GuiOptionsAddForNextWidget(UI.gui, GUI_OPTION.Align_HorizontalCenter)
	GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_total_proj") .. tostring(total_projectiles))

	local highest_dps = GlobalsGetValue(ModID .. "highest_dps", "") --渲染dps数据，伤害来自假人
	if #highest_dps > 0 then
		GuiOptionsAddForNextWidget(UI.gui, GUI_OPTION.Align_HorizontalCenter)
		GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_dps") .. highest_dps)
	end

	local total_damage = GlobalsGetValue(ModID .. "total_damage", "") --渲染总伤数据，伤害来自假人
	if #total_damage > 0 then
		GuiOptionsAddForNextWidget(UI.gui, GUI_OPTION.Align_HorizontalCenter)
		GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_total_damage") .. total_damage)
	end

	GuiLayoutEnd(UI.gui)
	GuiLayoutEndLayer(UI.gui)
	if highest_damage_projectile ~= nil then
		local esx, esy = get_screen_position(EntityGetTransform(highest_damage_projectile))
		GuiText(UI.gui, esx, esy, thousands_separator(highest_projectile_damage))
	end
end

local function PickerGap(gap)
	return 19 + gap * 22
end

local function ClickSound()
    GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", GameGetCameraPos())
end

function ToggleOptionsCB(_, _, _, iy, this_enable)
    if not this_enable then
        return
    end
	UI.MoveImagePicker("ProtectionBlindness", PickerGap(0), iy + 20, 8, 0, GameTextGet("$wand_editor_protection_blindness"),
        "mods/wand_editor/files/gui/images/protection_blindness.png", nil, nil, nil, true, true, true)
	
	UI.MoveImagePicker("ProtectionAll", PickerGap(1), iy + 20, 8, 0, GameTextGet("$wand_editor_protection_all"),
		"mods/wand_editor/files/gui/images/protection_all.png", nil, nil, nil, true, true, true)

	UI.MoveImagePicker("ProtectionPoly", PickerGap(2), iy + 20, 8, 0, GameTextGet("$wand_editor_protection_poly"),
		"mods/wand_editor/files/gui/images/protection_poly.png", nil, nil, nil, true, true, true)

	UI.MoveImagePicker("LockHP", PickerGap(3), iy + 20, 8, 0, GameTextGet("$wand_editor_lock_hp"),
		"mods/wand_editor/files/gui/images/lock_hp.png", nil, nil, nil, true, true, true)

	UI.MoveImagePicker("DamageInfo", PickerGap(4), iy + 20, 8, 0, GameTextGet("$wand_editor_damage_info"),
		"mods/wand_editor/files/gui/images/damage_info.png", nil, nil, nil, true, true, true)

	UI.MoveImagePicker("NoRecoil", PickerGap(5), iy + 20, 8, 0, GameTextGet("$wand_editor_no_recoil"),
		"mods/wand_editor/files/gui/images/no_recoil.png", nil, nil, nil, true, true, true)

	UI.MoveImagePicker("DisableParticles", PickerGap(6), iy + 20, 8, 0, GameTextGet("$wand_editor_no_particles"),
		"mods/wand_editor/files/gui/images/disable_particles.png", nil, nil, nil, true, true, true)

	UI.MoveImagePicker("DisableProj", PickerGap(7), iy + 20, 8, 0, GameTextGet("$wand_editor_no_proj"),
		"mods/wand_editor/files/gui/images/disable_projectiles.png", nil, nil, nil, true, true, true)

	UI.MoveImagePicker("UnlimitedSpells", PickerGap(0), iy + 40, 8, 0, GameTextGet("$wand_editor_unlimited_spells"),
		"mods/wand_editor/files/gui/images/unlimited_spells.png", nil, nil, nil, true, true, true)

	UI.MoveImagePicker("InfFly", PickerGap(1), iy + 40, 8, 0, GameTextGet("$wand_editor_inf_fly"),
        "mods/wand_editor/files/gui/images/inf_fly.png", nil, nil, nil, true, true, true)

	UI.MoveImagePicker("QuickTP", PickerGap(2), iy + 40, 8, 0, GameTextGet("$wand_editor_tp"),
        "mods/wand_editor/files/gui/images/tp.png", nil, nil, nil, true, true, true)
		
	UI.MoveImagePicker("EditWandsEverywhere", PickerGap(3), iy + 40, 8, 0,
		GameTextGet("$wand_editor_edit_wands_everywhere"),
		"mods/wand_editor/files/gui/images/edit_wands_everywhere.png", nil, nil, nil, true, true, true)

	UI.MoveImagePicker("AlwaysDrawWandEditBox", PickerGap(4), iy + 40, 8, 0,
		GameTextGet("$wand_editor_always_draw_wand_edit_box"),
		"mods/wand_editor/files/gui/images/always_draw_wand_edit_box.png", nil, nil, nil, true, true, true)

	UI.MoveImagePicker("KeyBoardInput", PickerGap(5) + 1, iy + 40, 8, 0, GameTextGet("$wand_editor_keyboard_input"),
		"mods/wand_editor/files/gui/images/keyboard_input.png", nil, nil, nil, true, true, true)

	UI.MoveImagePicker("DisableSpellWobble", PickerGap(6), iy + 40, 8, 0,
		GameTextGet("$wand_editor_disable_spell_wobble"),
        "mods/wand_editor/files/gui/images/disable_spell_wobble.png", nil, nil, nil, true, true, true)
    local LabSettingKey = ModID .. "SpellLab"
    local SrcPlayerXKey = ModID .. "SpellLab_player_x"
	local SrcPlayerYKey = ModID .. "SpellLab_player_y"
    local LabStatus = ModSettingGet(LabSettingKey)
	local HoverSpellLab = function ()
        local _, _, hover = GuiGetPreviousWidgetInfo(UI.gui)
        local tips
        if LabStatus then
            tips = GameTextGet("$wand_editor_spell_lab_button_leave")
        else
            tips = GameTextGet("$wand_editor_spell_lab_button_enter")
        end
		UI.tooltips(function ()
			GuiText(UI.gui,0,0,tips)
		end,nil,8)
		if hover then
			
		end
	end
    local ClickSpellLab = function(left_click, right_click)
        if left_click then
            local player = GetPlayer()
            if not LabStatus and player then --未开启的时候
                local x, y = EntityGetTransform(player)
                ModSettingSet(SrcPlayerXKey, x)
                ModSettingSet(SrcPlayerYKey, y)
                GameSetCameraPos(12200, -5900)
                EntitySetTransform(player, 12200, -5900)
            else --开启的时候
                local x = ModSettingGet(SrcPlayerXKey) or 0
                local y = ModSettingGet(SrcPlayerYKey) or 0
                GameSetCameraPos(x, y)
                EntitySetTransform(player, x, y)
            end
            LabStatus = not LabStatus
            ModSettingSet(LabSettingKey, LabStatus)
        end
        if right_click and LabStatus then --用一种奇怪的方法规避内部检查
            local list = EntityGetInRadiusWithTag(12200, -5900, 750, "player_unit")
            if #list == 0 then
				GamePrint(GameTextGet("$wand_editor_spell_lab_button_reset_error"))
				return
			end
            local GetResetCount = function()
                local t = Cpp.GetDirectoryPath("mods/wand_editor/files/biome_impl/wand_lab/reset")
                return Cpp.PathGetFileName(t.File[1])
            end
            local AddResetCount = function()
                local k = GetResetCount()
				k = tonumber(k) + 1
                local t = Cpp.GetDirectoryPath("mods/wand_editor/files/biome_impl/wand_lab/reset")
                Cpp.Rename(t.File[1], "mods/wand_editor/files/biome_impl/wand_lab/reset/" .. tostring(k))
				Cpp.Rename("mods/wand_editor/files/biome_impl/wand_lab/reset_xml/"..tostring(k-1),"mods/wand_editor/files/biome_impl/wand_lab/reset_xml/"..tostring(k))
            end
			local XmlSrcPath = "mods/wand_editor/files/biome_impl/wand_lab/reset/"
            local ResetXml = UI.UserData["ResetXmlBuffer"]
            if ResetXml == nil then
                ResetXml = Nxml.parse(ReadFileAll("mods/wand_editor/files/biome_impl/wand_lab/overwrite.xml"))
                for _, v in pairs(ResetXml.children) do
                    if v.name == "PixelSceneComponent" then
                        UI.UserData["ResetXmlPathBuffer"] = v
                        break
                    end
                end
                UI.UserData["ResetXmlBuffer"] = ResetXml
            end
			AddResetCount()
			print(GetResetCount())
			local count = GetResetCount()
            UI.UserData["ResetXmlPathBuffer"].attr.pixel_scene = XmlSrcPath..count
			local file = io.open("mods/wand_editor/files/biome_impl/wand_lab/reset_xml/"..tostring(count), "w") --将新内容写进文件中
			file:write(tostring(ResetXml))
			file:close()
            local list = EntityGetInRadiusWithTag(12200, -5900, 525,"polymorphable_NOT")
            for _, v in pairs(list) do
                if EntityGetName(v) == "wand_editor_dummy_target" then
                    EntityKill(v)
                end
            end
            EntityLoad("mods/wand_editor/files/biome_impl/wand_lab/reset_xml/" .. tostring(count), 12200, -5900)
			GamePrint(GameTextGet("$wand_editor_spell_lab_button_reset_done"))
		end
    end
    if not LabStatus then
        GuiOptionsAddForNextWidget(UI.gui, GUI_OPTION.DrawSemiTransparent)
    end
	GuiZSetForNextWidget(UI.gui, UI.GetZDeep())
	UI.MoveImageButton("EnterSpellLab", PickerGap(0), iy + 60, "mods/wand_editor/files/gui/images/wand_lab_icon.png",nil,HoverSpellLab,ClickSpellLab,nil,true)
		
    local UpdateHover = function()
        local _, _, hover = GuiGetPreviousWidgetInfo(UI.gui)
		UI.tooltips(function() --根据状态改变悬浮提示
			GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_check_update"))
			if UI.UserData["UpdateCheck"] == nil then
				GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_no_checking"))
			elseif UI.UserData["UpdateCheck"] == "testing" then
				GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_checking"))
			elseif UI.UserData["UpdateCheck"] == "error" then
				GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_connect_failed"))
			elseif UI.UserData["UpdateCheck"] == "latest" then
				GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_latest_ver"))
			elseif UI.UserData["UpdateCheck"] == "new" then
				if UI.UserData["DownloadStatus"] == nil then
					GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_new_ver", UI.UserData["UpdateDataVer"],
						ModVersion))
				elseif UI.UserData["DownloadStatus"] == "download" then
					GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_new_ver_downloading"))
				elseif UI.UserData["DownloadStatus"] == "error" then
					GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_new_ver_failed"))
				elseif UI.UserData["DownloadStatus"] == "done" then
					GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_download_complete"))
				end
			end
		end, nil, 8)
        if hover then
            if UI.UserData["DownloadStatus"] == "done" and InputIsKeyDown(Key_c) then
                Cpp.SetClipboard(Cpp.CurrentPath() .. "/mods")
            end
        end
    end
	
    local UpdateClick = function(click)
        if UI.UserData["UpdateCheck"] == "new" then --如果确认有新版本
            if click and UI.UserData["DownloadThreadHandle"] == nil and UI.UserData["DownloadStatus"] == nil or (click and UI.UserData["DownloadStatus"] == "error") then
                local function DownloadNewVer(verStr)
                    local link = "/KagiamamaHIna/Wand-Editor/releases/download/v" ..
                    verStr .. "/wand_editor_v" .. verStr .. ".zip"
                    local https = require("ssl.https")
                    local ltn12 = require("ltn12")
                    require("github_mirror")
                    local code = 0
                    local Returns
                    -- 准备sink，用于收集响应体数据
                    local response_chunks = {}
                    local response_sink = ltn12.sink.table(response_chunks)
                    Returns = { https.request {
                        url = CurrentMirror(link),
                        sink = response_sink,
                    } }
                    code = Returns[2]
                    if code ~= 200 then --请求原始网页
                        Returns = { https.request {
                            url = GitHub_Link(link),
                            sink = response_sink,
                        } }
                        code = Returns[2]
                    end
                    return response_chunks, code
                end
                local runner = effil.thread(DownloadNewVer)
                UI.UserData["DownloadThreadHandle"] = runner(UI.UserData["UpdateDataVer"]) --因为我发行的版本号都是有规则的，所以可以这么干 UI.UserData["UpdateDataVer"]
                UI.UserData["DownloadStatus"] = "download"
                ClickSound()
                UI.TickEventFn["UpdateFn"] = function()
                    if UI.UserData["DownloadThreadHandle"] and UI.UserData["DownloadStatus"] == "download" then
                        local handle = UI.UserData["DownloadThreadHandle"]
                        local status = handle:status()
                        if status ~= "completed" then --判断线程是否执行完毕
                            return
                        end
                        local response_chunks, code = handle:get()
                        if code == 200 then                  --执行完毕的时候，并且页面请求正常
                            local file = io.open("mods/wand_editor_new_ver.zip", "wb")
                            for _, chunk in pairs(effil.dump(response_chunks)) do --将二进制数据写入文件
                                file:write(chunk)
                            end
                            file:close()
                            UI.UserData["DownloadStatus"] = "done"
                            GamePrint(GameTextGet("$wand_editor_new_ver_done_tip"))
                        else
                            UI.UserData["DownloadStatus"] = "error"
                            GamePrint(GameTextGet("$wand_editor_new_ver_failed_tip"))
                        end
                        UI.UserData["DownloadThreadHandle"] = nil --已经完成了，可以移除
                        UI.TickEventFn["UpdateFn"] = nil
                    end
                end
            end
        end
        local function RequestDefine()
            local address = "/KagiamamaHIna/Wand-Editor/main/files/libs/define.lua" --合并主分支的时候记得改
            local https = require("ssl.https")
            require("github_mirror")
            local result = { https.request(CurrentMirror(address, true)) }
            if result[2] ~= 200 then
                result = { https.request(GitHub_Link(address, true)) } --如果镜像不行就尝试访问原始链接
            end
            return unpack(result)
        end
        if (click and UI.UserData["UpdateCheck"] == nil) or (click and UI.UserData["UpdateCheck"] == "error") then
            local runner = effil.thread(RequestDefine)
            UI.UserData["UpdateThreadHandle"] = runner()
            UI.UserData["UpdateCheck"] = "testing"
            ClickSound()
            UI.TickEventFn["UpdateCheckFn"] = function() --分离方便检测
                if UI.UserData["UpdateThreadHandle"] and UI.UserData["UpdateCheck"] == "testing" then
                    local handle = UI.UserData["UpdateThreadHandle"]
                    local status = handle:status()
                    if status ~= "completed" then
                        return
                    end
                    local text, code = handle:get()
                    if code == 200 then --200代表请求正确
                        local fn = loadstring(text)
                        local env = {}
                        setfenv(fn, env)() --设置环境执行以获得版本信息
                        if true or env.ModVersion ~= ModVersion then
                            UI.UserData["UpdateCheck"] = "new"
                            UI.UserData["UpdateDataVer"] = env.ModVersion
                        else --如果一致，则认为是最新版
                            UI.UserData["UpdateCheck"] = "latest"
                        end
                        GamePrint(GameTextGet("$wand_editor_check_done_tip"))
                    else
                        UI.UserData["UpdateCheck"] = "error"
                        GamePrint(GameTextGet("$wand_editor_check_failed_tip"))
                    end
                    UI.TickEventFn["UpdateCheckFn"] = nil
                    UI.UserData["UpdateThreadHandle"] = nil --垃圾回收
                end
            end
        end
    end
	GuiZSetForNextWidget(UI.gui, UI.GetZDeep())
	UI.MoveImageButton("UpdateMod", PickerGap(1), iy + 60, "mods/wand_editor/files/gui/images/update_mod.png", nil, UpdateHover, UpdateClick, nil, true)
		
	GuiZSetForNextWidget(UI.gui, UI.GetZDeep())
	UI.MoveImageButton("ModAbout", PickerGap(2), iy + 60, "mods/wand_editor/files/gui/images/about.png", nil, function()
        local _, _, hover = GuiGetPreviousWidgetInfo(UI.gui)
		UI.tooltips(function()
			GuiText(UI.gui, 0, 0, ModVersion)
			GuiText(UI.gui, 0, 0, ModLink)
			GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_about_copy_link_tips"))
			if Cpp.PathExists("mods/wand_editor/cache/avatar.png") then
				GuiImage(UI.gui, UI.NewID("AuthorAvatar"), 0, 0, "mods/wand_editor/cache/avatar.png", 1, 0.5 / UI.GetScale())
			end
		end, nil, 8)
		if hover then
			if InputIsKeyDown(Key_c) then
				Cpp.SetClipboard(ModLink)
			end
		end
	end, nil, nil, true)
end

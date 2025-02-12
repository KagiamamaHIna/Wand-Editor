dofile_once("mods/wand_editor/files/misc/bygoki/lib/helper.lua")
local Nxml = dofile_once("mods/wand_editor/files/libs/nxml.lua")
local fastConcatStr = Cpp.ConcatStr
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
    local function InfoCallBack(s_x, s_y)
        GuiLayoutBeginLayer(UI.gui)
        GuiLayoutBeginVertical(UI.gui, s_x, s_y + 5, true)
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
		GuiZSetForNextWidget(UI.gui,UI.GetZDeep())
        GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_total_proj_dmg") .. thousands_separator(total_projectile_damage))

        GuiOptionsAddForNextWidget(UI.gui, GUI_OPTION.Align_HorizontalCenter)
		GuiZSetForNextWidget(UI.gui,UI.GetZDeep())
        GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_total_proj") .. tostring(total_projectiles))

        local highest_dps = GlobalsGetValue(ModID .. "highest_dps", "") --渲染dps数据，伤害来自假人
        if #highest_dps > 0 then
            GuiOptionsAddForNextWidget(UI.gui, GUI_OPTION.Align_HorizontalCenter)
			GuiZSetForNextWidget(UI.gui,UI.GetZDeep())
            GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_dps") .. highest_dps)
        end

        local total_damage = GlobalsGetValue(ModID .. "total_damage", "") --渲染总伤数据，伤害来自假人
        if #total_damage > 0 then
            GuiOptionsAddForNextWidget(UI.gui, GUI_OPTION.Align_HorizontalCenter)
			GuiZSetForNextWidget(UI.gui,UI.GetZDeep())
            GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_total_damage") .. total_damage)
        end

        GuiLayoutEnd(UI.gui)
        GuiLayoutEndLayer(UI.gui)
        if highest_damage_projectile ~= nil then
            local esx, esy = get_screen_position(EntityGetTransform(highest_damage_projectile))
			GuiZSetForNextWidget(UI.gui,UI.GetZDeep())
            GuiText(UI.gui, esx, esy, thousands_separator(highest_projectile_damage))
        end
    end
	GuiZSetForNextWidget(UI.gui,UI.GetZDeep())
	UI.MoveImageButton("DamageInfoMoveBTN",UI.ScreenWidth * 0.5,2,"mods/wand_editor/files/gui/images/move.png",InfoCallBack,function ()
		GuiTooltip(UI.gui,GameTextGet("$wand_editor_picker_desc"),"")
	end)
end

local function PickerGap(gap)
	return 19 + gap * 22
end

local AutoUpdateNoPrint = function (str)
	if not ModSettingGet(ModID..".auto_update") then
		GamePrint(str)
	end
end

local WriteUpdateFilePath = "mods/wand_editor_new_ver.zip"

local UpdateFn = function(_click, isBtn)
    local function ClickSoundUpdate()
        if not ModSettingGet(ModID .. ".auto_update") then
            GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", GameGetCameraPos())
        end
    end
    local click = _click
    if not isBtn then
        click = click or ModSettingGet(ModID .. ".auto_update")
    end
    local RequestRestart
    if not ModSettingGet(ModID .. ".auto_update") then
        RequestRestart = click
    elseif ModSettingGet(ModID .. ".auto_update") and UI.UserData["LastUpdateErrorTime"] then --自动重置
        local _, _, _, hour = GameGetDateAndTimeLocal()
        if hour - UI.UserData["LastUpdateErrorTime"] > 0 then                              --请求失败就隔一个小时自动重新请求/下载一次
            RequestRestart = true
        end
    end
    if ModSettingGet(ModID .. ".auto_update") and isBtn then
        RequestRestart = _click
    end
    if UI.UserData["UpdateCheck"] == "new" then --如果确认有新版本
        if click and UI.UserData["DownloadThreadHandle"] == nil and UI.UserData["DownloadStatus"] == nil or (RequestRestart and UI.UserData["DownloadStatus"] == "error") then
            local function DownloadNewVer(verStr, intptr, GithubFlag)
                local link = "/KagiamamaHIna/Wand-Editor/releases/download/v" ..
                    verStr .. "/wand_editor_v" .. verStr .. ".zip"
                local https = require("ssl.https")
                local ltn12 = require("ltn12")
                require("github_mirror")
                local Cpp = require("WandEditorDll")
                local code = 0
                local Returns
                -- 准备sink，用于收集响应体数据
                local response_chunks = {}
                local response_sink = ltn12.sink.table(response_chunks)
                local function sinkfn(chunk, err) --闭包函数和指针实现数据共享和下载的数据量读取
                    if chunk then
                        Cpp.SetIntPtrV(intptr, Cpp.GetIntPtrV(intptr) + #chunk)
                    end
                    return response_sink(chunk, err)
                end
                local function RequestGithub()
                    Returns = { https.request {
                        url = GitHub_Link(link),
                        sink = sinkfn,
                    } }
                end
                local function RequestMirror()
                    Returns = { https.request {
                        url = CurrentMirror(link),
                        sink = sinkfn,
                    } }
                end
                if GithubFlag then --根据谁先获得，来进行数据获取执行
                    RequestGithub()
                else
                    RequestMirror()
                end
                code = Returns[2]
                if code ~= 200 then --请求另外一个
                    Cpp.SetIntPtrV(intptr, 0) --上一个请求失败了，这里我觉得要重置一下计数器
                    if GithubFlag then --反过来
                        RequestMirror()
                    else
                        RequestGithub()
                    end
                    code = Returns[2]
                end
                return response_chunks, code
            end

            UI.UserData["SizeIntPtr"] = Cpp.NewIntPtr(0)
            local runner = effil.thread(DownloadNewVer)
			--因为我发行的版本号都是有规则的，所以可以这么干 UI.UserData["UpdateDataVer"]
            UI.UserData["DownloadThreadHandle"] = runner(UI.UserData["UpdateDataVer"], UI.UserData["SizeIntPtr"], UI.UserData["GetForGithub"])
            UI.UserData["DownloadStatus"] = "download"
            ClickSoundUpdate()

            UI.MiscEventFn["UpdateFn"] = function()
                if UI.UserData["DownloadThreadHandle"] and UI.UserData["DownloadStatus"] == "download" then
                    local handle = UI.UserData["DownloadThreadHandle"]
                    local status = handle:status()
                    if status ~= "completed" then --判断线程是否执行完毕
                        return
                    end
                    local response_chunks, code = handle:get()
                    if code == 200 then                     --执行完毕的时候，并且页面请求正常
                        local file = io.open(WriteUpdateFilePath, "wb")
                        for _, chunk in pairs(effil.dump(response_chunks)) do --将二进制数据写入文件
                            file:write(chunk)
                        end
                        file:close()
                        UI.UserData["DownloadStatus"] = "done"
                        AutoUpdateNoPrint(GameTextGet("$wand_editor_new_ver_done_tip"))
                        UI.UserData["LastUpdateErrorTime"] = nil
                    else
                        UI.UserData["DownloadStatus"] = "error"
                        AutoUpdateNoPrint(GameTextGet("$wand_editor_new_ver_failed_tip"))
                        if ModSettingGet(ModID .. ".auto_update") then
                            local _, _, _, hour = GameGetDateAndTimeLocal()
                            UI.UserData["LastUpdateErrorTime"] = hour
                        else
                            UI.UserData["LastUpdateErrorTime"] = nil
                        end
                    end
                    UI.UserData["DownloadThreadHandle"] = nil --已经完成了，可以移除
                    UI.MiscEventFn["UpdateFn"] = nil
                end
            end
        end
    end
    local function RequestDefine(GithubFlag)
        local address = "/KagiamamaHIna/Wand-Editor/refs/heads/main/files/libs/define.lua" --合并主分支的时候记得改
        local https = require("ssl.https")
        require("github_mirror")
        local result
        if GithubFlag then
            result = { https.request(GitHub_Link(address, true)) }
        else
            result = { https.request(CurrentMirror(address, true)) }
        end
        return unpack(result)
    end
    if (click and UI.UserData["UpdateCheck"] == nil) or (RequestRestart and UI.UserData["UpdateCheck"] == "error") then
        local runner = effil.thread(RequestDefine)
        local runner2 = effil.thread(RequestDefine)
        UI.UserData["UpdateThreadHandles"] = { runner(false), runner2(true) }
        UI.UserData["UpdateCheck"] = "testing"
        ClickSoundUpdate()
        UI.MiscEventFn["UpdateCheckFn"] = function() --分离方便检测
            if UI.UserData["UpdateThreadHandles"] and UI.UserData["UpdateCheck"] == "testing" then
                local handles = UI.UserData["UpdateThreadHandles"]
                local status = handles[1]:status() or handles[2]:status()
                if status ~= "completed" then
                    return
                end
                local handle1 = handles[1]
                local handle2 = handles[2]
                local handle
                local _, code1 = handle1:get()
                local _, code2 = handle2:get()

                if handle1:status() == "completed" then
                    if code1 == 200 then
                        handle = handle1
                        UI.UserData["GetForGithub"] = false
                    end
                else
                    if code2 == 200 then
                        handle = handle2
                        UI.UserData["GetForGithub"] = true
                    end
                end
                local text, code
                if handle == nil or (code1 ~= 200 and code2 ~= 200) then --完全失败
                    code = false
                else
                    text, code = handle:get()
                end

                if code == 200 then --200代表请求正确
                    local fn = loadstring(text)
                    local env = {}
                    setfenv(fn, env)() --设置环境执行以获得版本信息
                    local numList = split(env.ModVersion or "", ".")
                    local LocalNumList = split(ModVersion, ".")
                    local newFlag = true
                    if env.ModVersion == ModVersion then --检查两个字符串是否相等
                        newFlag = false
                    end
                    if newFlag then --不相等的情况下进一步检查
                        local Size = #numList
                        if Size < #LocalNumList then --取大的
                            Size = #LocalNumList
                        end
                        for i = Size, 1, -1 do
                            local LocalNum = tonumber(LocalNumList[i]) or 0
                            local num = tonumber(numList[i]) or 0
                            if LocalNum > num then --大到小检查，只要我们有一个大于对面的则认为是最新版
                                newFlag = false
                                break
                            end
                        end
                    end
					if env.NoRewriteList ~= nil then--如果是空就用本地的
						NoRewriteList = env.NoRewriteList
					end
                    if newFlag then
                        UI.UserData["UpdateCheck"] = "new"
                        UI.UserData["UpdateDataVer"] = env.ModVersion
                    else --如果一致，则认为是最新版
                        UI.UserData["UpdateCheck"] = "latest"
                    end
                    AutoUpdateNoPrint(GameTextGet("$wand_editor_check_done_tip"))
                else
                    UI.UserData["UpdateCheck"] = "error"
                    AutoUpdateNoPrint(GameTextGet("$wand_editor_check_failed_tip"))
                    if ModSettingGet(ModID .. ".auto_update") then
                        local _, _, _, hour = GameGetDateAndTimeLocal()
                        UI.UserData["LastUpdateErrorTime"] = hour
                    else
                        UI.UserData["LastUpdateErrorTime"] = nil
                    end
                end
                UI.MiscEventFn["UpdateCheckFn"] = nil
                UI.UserData["UpdateThreadHandles"] = nil --垃圾回收
            end
        end
    end
end

local UpdateClick = function(click)
    UpdateFn(click, true)
end

local ThreadUnZip = function(effil, _WriteUpdateFilePath, _NoRewriteList)
    local Cpp = require("WandEditorDll")
	local fastConcatStr = Cpp.ConcatStr
    local function RemoveExclude(t, ExcludeList) --深拷贝并移除不要移除的路径与文件
        local result = {}
        for k, v in pairs(t) do
            result[k] = {}
            for _, v2 in pairs(v) do
                local flag
                for _, ExcludeStr in pairs(ExcludeList) do
                    flag = string.find(v2, ExcludeStr, 1, true)
                    if flag then
                        break
                    end
                end
                if flag == nil then
                    result[k][#result[k] + 1] = v2
                end
            end
        end
        return result
    end

    local function IncludePathRemove(t, newVerT) --生成一个需要删除的文件的表
        local result = {}
        local MorePath = {}
        for _, v in pairs(t.Path) do --构造多出来的路径表
            local flag = false
            for _, p in pairs(newVerT.Path) do
                p = p:gsub("wand_editor/cache/", "")
                if v == p then --如果遍历到有，则代表存在，不需要删除
                    flag = true
                    break
                end
            end
            if not flag then
                MorePath[#MorePath + 1] = v
            end
        end
        local tempList = {}
        for _, v in pairs(t.File) do --移除多余路径下的多余文件
            local flag
            for _, p in pairs(MorePath) do
                flag = string.find(v, p, 1, true)
                if flag then
                    break
                end
            end
            if flag == nil then
                tempList[#tempList + 1] = v
            end
        end
        for _, v in pairs(tempList) do --移除多余文件
            local flag
            for _, p in pairs(newVerT.File) do
                p = p:gsub("wand_editor/cache/", "")
                if v == p then --如果遍历到有，则代表存在，不需要删除
                    flag = true
                    break
                end
            end
            if not flag then
                result[#result + 1] = v
            end
        end
        for _, v in pairs(MorePath) do --深拷贝合并
            result[#result + 1] = v
        end
        return result
    end
	local function AddOriginalPath(t)
		local newTable = {}
		
		for k,t1 in pairs(t) do
			local key = "O_"..k
			newTable[key] = {}
			for k2,v in pairs(t1) do
				newTable[key][k2] = v:gsub("wand_editor/cache/", "")
			end
		end
		for k,v in pairs(newTable) do
			t[k] = v
		end
		return t
	end
    local function ForThreadSerializeTable(tbl, indent)
        indent = indent or ""
        local parts = {}
        local partsKey = 1

        local _tostr = tostring
        local _type = type
        local is_array = #tbl > 0 or tbl[0] ~= nil
        for k, v in pairs(tbl) do
            local key
            if is_array and _type(k) == "number" then
                key = fastConcatStr("[", _tostr(k), "] = ")
            else
                key = fastConcatStr("[\"", _tostr(k), "\"] = ")
            end

            if _type(v) == "table" then
                parts[partsKey] = fastConcatStr(indent, key, "{\n")
                parts[partsKey + 1] = ForThreadSerializeTable(v, indent .. "    ")
                parts[partsKey + 2] = fastConcatStr(indent, "},\n")
                partsKey = partsKey + 3
            elseif _type(v) == "boolean" or _type(v) == "number" then
                parts[partsKey] = fastConcatStr(indent, key, _tostr(v), ",\n")
                partsKey = partsKey + 1
            else
                parts[partsKey] = string.format("%s%s%q,\n", indent, key, v)
                partsKey = partsKey + 1
            end
        end
        return table.concat(parts)
    end
	--代码逻辑开始
	Cpp.RemoveAll("mods/wand_editor/cache/wand_editor/")
	Cpp.Remove("mods/wand_editor/cache/CurrentPath.lua")
	Cpp.Remove("mods/wand_editor/cache/NewPaths.lua")
	local NoRewriteList = effil.dump(_NoRewriteList)
    local PreDeletePaths = RemoveExclude(Cpp.GetDirectoryPathAll("mods/wand_editor/"), NoRewriteList)
	Cpp.Uncompress(_WriteUpdateFilePath, "mods/wand_editor/cache/")
	Cpp.Remove(WriteUpdateFilePath)     --移除压缩文件
	local newPaths = AddOriginalPath(Cpp.GetDirectoryPathAll("mods/wand_editor/cache/wand_editor/"))
	PreDeletePaths = IncludePathRemove(PreDeletePaths, newPaths)
	local file = io.open("mods/wand_editor/cache/PreDeletePaths.lua", "w") --将需要删除的数据写入文件
	file:write("return {\n" .. ForThreadSerializeTable(PreDeletePaths, "") .. "}")
	file:close()

	for _,v in pairs(newPaths.O_Path) do--提前创建文件夹
		Cpp.CreateDirs(v)
	end

	file = io.open("mods/wand_editor/cache/NewPaths.lua", "w") --将新路径写入文件
	file:write("return {\n" .. ForThreadSerializeTable(newPaths, "") .. "}")
    file:close()
end

--检查下载完成与解压完成
local UncompressNewZipFn = function()
	if UI.UserData["DownloadStatus"] == "done" and ModSettingGet(ModID .. ".auto_update") then
        if Cpp.PathExists(WriteUpdateFilePath) and UI.UserData["UncompressUpdateZip"] == nil and UI.UserData["UncompressUpdateHandle"] == nil then
            local runner = effil.thread(ThreadUnZip)
			UI.UserData["UncompressUpdateHandle"] = runner(effil, WriteUpdateFilePath, NoRewriteList)--多线程执行防止主线程阻塞
        elseif UI.UserData["UncompressUpdateHandle"] then
            local handle = UI.UserData["UncompressUpdateHandle"]
			if handle:status() == "completed" then
				UI.UserData["UncompressUpdateZip"] = true
                UI.UserData["UncompressUpdateHandle"] = nil
				--三个需要提前覆写的
                RewriteBinFile("mods/wand_editor/init.lua", "mods/wand_editor/cache/wand_editor/init.lua")
                RewriteBinFile("mods/wand_editor/settings.lua", "mods/wand_editor/cache/wand_editor/settings.lua")
				RewriteBinFile("mods/wand_editor/unsafeFn.lua", "mods/wand_editor/cache/wand_editor/unsafeFn.lua")
				local file = io.open("mods/wand_editor/cache/UpdateFlag", "w") --新建标记文件
				file:close()
			end
		end
	end
end

UI.MiscEventFn["ListenerAutoUpdate"] = function()
    if UI.UserData["UpdateCheck"] == "latest" or (UI.UserData["DownloadStatus"] == "done" and UI.UserData["UncompressUpdateZip"]) then
        --如果检查完成且是最新版/下载完成且预处理完成，移除这两个检查用的，停止检查
        UI.MiscEventFn["AutoUpdate"] = nil
        UI.MiscEventFn["ListenerAutoUpdate"] = nil
    end

    if GetPlayer() and UI.UserData["LinstenerUpdateStart"] == nil then
        UI.UserData["LinstenerUpdateStart"] = true
    end

    --UI.UserData["DownloadStatus"] = "done"--调试用
    --未知原因，疑似太早执行会造成主线程堵塞，然后卡至请求结束，缓一段时间到玩家生成就没有此现象
    if not GetPlayer() and UI.UserData["LinstenerUpdateStart"] == nil and not ModSettingGet(ModID .. ".auto_update") then
        if UI.MiscEventFn["AutoUpdate"] then
            UI.MiscEventFn["AutoUpdate"] = nil
        end
        return
    end
    if UI.MiscEventFn["AutoUpdate"] == nil and ModSettingGet(ModID .. ".auto_update") then
        UI.MiscEventFn["AutoUpdate"] = function() --增加检测更新的函数
            UpdateFn(true, false)
            --自动检测是否下载完成和是否需要解压
            UncompressNewZipFn()
        end
    elseif UI.MiscEventFn["AutoUpdate"] and not ModSettingGet(ModID .. ".auto_update") then
        UI.MiscEventFn["AutoUpdate"] = nil
    end
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
	
	local LockHPCB = function (_, LockHP_right_click)--右键使血量恢复至满血的实现
			local player = GetPlayer()
			if LockHP_right_click and player then
            local damage_model = EntityGetFirstComponent(player, "DamageModelComponent")
			local MaxHP
            if damage_model then
                MaxHP = ComponentGetValue2(damage_model, "max_hp")
				if UI.UserData["LockHPValue"] ~= nil then
					UI.UserData["LockHPValue"] = MaxHP
				end
				ComponentSetValue2(damage_model, "hp", MaxHP)
			end
		end
	end
	UI.MoveImagePicker("LockHP", PickerGap(3), iy + 20, 8, 0, GameTextGet("$wand_editor_lock_hp"),
		"mods/wand_editor/files/gui/images/lock_hp.png", nil, LockHPCB, nil, true, true, true)

	UI.MoveImagePicker("DamageInfo", PickerGap(4), iy + 20, 8, 0, GameTextGet("$wand_editor_damage_info"),
		"mods/wand_editor/files/gui/images/damage_info.png", nil, nil, nil, true, true, true)

	UI.MoveImagePicker("NoRecoil", PickerGap(5), iy + 20, 8, 0, GameTextGet("$wand_editor_no_recoil"),
		"mods/wand_editor/files/gui/images/no_recoil.png", nil, nil, nil, true, true, true)

	UI.MoveImagePicker("DisableParticles", PickerGap(6), iy + 20, 8, 0, GameTextGet("$wand_editor_no_particles"),
		"mods/wand_editor/files/gui/images/disable_particles.png", nil, nil, nil, true, true, true)

	UI.MoveImagePicker("DisableProj", PickerGap(7), iy + 20, 8, 0, GameTextGet("$wand_editor_no_proj"),
		"mods/wand_editor/files/gui/images/disable_projectiles.png", nil, nil, nil, true, true, true)

	UI.MoveImagePicker("DisablePlayerGravity", PickerGap(8), iy + 20, 8, 0, GameTextGet("$wand_editor_disable_player_gravity"),
        "mods/wand_editor/files/gui/images/disable_player_gravity.png", nil, nil, nil, true, true, true)

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
--[[
	UI.MoveImagePicker("KeyBoardInput", PickerGap(5) + 1, iy + 40, 8, 0, GameTextGet("$wand_editor_keyboard_input"),
		"mods/wand_editor/files/gui/images/keyboard_input.png", nil, nil, nil, true, true, true)]]

	UI.MoveImagePicker("DisableSpellWobble", PickerGap(5), iy + 40, 8, 0,
		GameTextGet("$wand_editor_disable_spell_wobble"),
        "mods/wand_editor/files/gui/images/disable_spell_wobble.png", nil, nil, nil, true, true, true)

	UI.MoveImagePicker("DisableWandHistory", PickerGap(6), iy + 40, 8, 0,
		GameTextGet("$wand_editor_disable_wand_history"),
        "mods/wand_editor/files/gui/images/disable_wand_history.png", nil, nil, nil, true, true, true)
	
	UI.MoveImagePicker("DisableSpellHover", PickerGap(7), iy + 40, 8, 0,
		GameTextGet("$wand_editor_disable_spell_hover"),
        "mods/wand_editor/files/gui/images/disable_spell_hover.png", nil, nil, nil, true, true, true)

	UI.MoveImagePicker(".remove_lighting", PickerGap(8), iy + 40, 8, 0,
		GameTextGet("$wand_editor_remove_lighting"),
        "mods/wand_editor/files/gui/images/remove_lighting.png", nil, nil, nil, true, true, true)

    local LabSettingKey = fastConcatStr(ModID , "SpellLab")
    local SrcPlayerXKey = fastConcatStr(ModID , "SpellLab_player_x")
	local SrcPlayerYKey = fastConcatStr(ModID , "SpellLab_player_y")
    local LabStatus = ModSettingGet(LabSettingKey)
	local HoverSpellLab = function ()
        local tips
        if LabStatus then
            tips = GameTextGet("$wand_editor_spell_lab_button_leave")
        else
            tips = GameTextGet("$wand_editor_spell_lab_button_enter")
        end
		UI.tooltips(function ()
			GuiText(UI.gui,0,0,tips)
		end,nil,8)
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
			local count = GetResetCount()
            UI.UserData["ResetXmlPathBuffer"].attr.pixel_scene = XmlSrcPath..count
			local file = io.open("mods/wand_editor/files/biome_impl/wand_lab/reset_xml/"..tostring(count), "w") --将新内容写进文件中
			file:write(tostring(ResetXml))
			file:close()
            local list = EntityGetInRadiusWithTag(12200, -5900, 530,"polymorphable_NOT")
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
					GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_new_ver", UI.UserData["UpdateDataVer"], ModVersion))
                elseif UI.UserData["DownloadStatus"] == "download" then
					local SizeString = "? nullptr error"
					if UI.UserData["SizeIntPtr"] then
						SizeString = Compose(ToBytesString, Cpp.GetIntPtrV)(UI.UserData["SizeIntPtr"])
					end
					GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_new_ver_downloading", SizeString))
				elseif UI.UserData["DownloadStatus"] == "error" then
                    GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_new_ver_failed"))
					if UI.UserData["SizeIntPtr"] then
						Cpp.Free(UI.UserData["SizeIntPtr"])
						UI.UserData["SizeIntPtr"] = nil
					end
				elseif UI.UserData["DownloadStatus"] == "done" then
                    GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_download_complete"))
					if UI.UserData["SizeIntPtr"] then
						Cpp.Free(UI.UserData["SizeIntPtr"])
						UI.UserData["SizeIntPtr"] = nil
					end
				end
			end
		end, nil, 8)
        if hover then
            if UI.UserData["DownloadStatus"] == "done" and InputIsKeyDown(Key_c) then
                Cpp.SetClipboard(Cpp.CurrentPath() .. "/mods")
            end
        end
    end
	UI.MoveImagePicker("SpellDepotHistoryMode", PickerGap(1), iy + 60, 8, 0,
		GameTextGet("$wand_editor_spell_depot_history"),
        "mods/wand_editor/files/gui/images/spell_depot_history.png", nil, nil, nil, true, true, true)

	UI.MoveImagePicker("SpellInfMana", PickerGap(2), iy + 60, 8, 0,
		GameTextGet("$wand_editor_spell_inf_mana"),
        "mods/wand_editor/files/gui/images/inf_mana.png", nil, nil, nil, true, true, true)
	
	GuiZSetForNextWidget(UI.gui, UI.GetZDeep())
	UI.MoveImageButton("UpdateMod", PickerGap(3), iy + 60, "mods/wand_editor/files/gui/images/update_mod.png", nil, UpdateHover, UpdateClick, nil, true)
    local reloadText = GameTextGet("$wand_editor_reload_spell_data")
	if UI.GetPickerStatus("ReloadSpellData") then
		reloadText = reloadText .."\n".. GameTextGet("$menu_mods_help_paused")
	end
    local ModAboutCB = function()
        local _, _, hover = GuiGetPreviousWidgetInfo(UI.gui)
        UI.tooltips(function()
            GuiText(UI.gui, 0, 0, ModVersion)
            GuiText(UI.gui, 0, 0, ModLink)
            GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_about_copy_link_tips"))
            if Cpp.PathExists("mods/wand_editor/cache/avatar.png") then
                GuiImage(UI.gui, UI.NewID("AuthorAvatar"), 0, 0, "mods/wand_editor/cache/avatar.png", 1,
                    0.5 / UI.GetScale())
            end
            if ModSettingGet(ModID .. "YukimiAvailable") and ModSettingGet(ModID .. "YukimiAvailableShow") then
                GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_yukimi_close"))
            elseif ModSettingGet(ModID .. "YukimiAvailable") and not ModSettingGet(ModID .. "YukimiAvailableShow") then
                GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_yukimi_open"))
            end
            if ModSettingGet(ModID .. "YukimiAvailable") and ModSettingGet(ModID .. "YukimiAlways") then
                GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_always_yukimi_close"))
            elseif ModSettingGet(ModID .. "YukimiAvailable") and not ModSettingGet(ModID .. "YukimiAlways") then
                GuiText(UI.gui, 0, 0, GameTextGet("$wand_editor_always_yukimi_open"))
            end
        end, nil, 8)
        if hover then
            if InputIsKeyDown(Key_c) then
                Cpp.SetClipboard(ModLink)
            end
        elseif not hover and UI.UserData["ModAboutConut"] then
            UI.UserData["ModAboutConut"] = nil
        end
    end
	local ModAboutClickCB = function (left_click, right_click)
        if left_click and ModSettingGet(ModID .. "YukimiAvailable") == nil then
            if UI.UserData["ModAboutConut"] == nil then
                UI.UserData["ModAboutConut"] = 1
            elseif UI.UserData["ModAboutConut"] < 2 then
                UI.UserData["ModAboutConut"] = UI.UserData["ModAboutConut"] + 1
            else
                ModSettingSet(ModID .. "YukimiAvailable", true)
                ModSettingSet(ModID .. "YukimiAvailableShow", true)
                ModSettingSet(ModID .. "YukimiAlways", false)
                UI.UserData["ModAboutConut"] = nil
            end
        end
		if ModSettingGet(ModID .. "YukimiAvailable") and left_click and (InputIsKeyDown(Key_LSHIFT) or InputIsKeyDown(Key_RSHIFT)) then
			ModSettingSet(ModID.."YukimiAlways",not ModSettingGet(ModID.."YukimiAlways"))		
		end
		if ModSettingGet(ModID.."YukimiAvailable") and right_click then
			ModSettingSet(ModID.."YukimiAvailableShow",not ModSettingGet(ModID.."YukimiAvailableShow"))
		end
	end
	if ModSettingGet("wand_editor.cache_spell_data") then
		UI.MoveImagePicker("ReloadSpellData", PickerGap(4), iy + 60, 8, 0, reloadText,
        "mods/wand_editor/files/gui/images/reload_spell_data.png", nil, nil, nil, true, true, true)

		GuiZSetForNextWidget(UI.gui, UI.GetZDeep())
		UI.MoveImageButton("ModAbout", PickerGap(5), iy + 60, "mods/wand_editor/files/gui/images/about.png", nil, ModAboutCB, ModAboutClickCB, nil, true)
	else
		GuiZSetForNextWidget(UI.gui, UI.GetZDeep())
		UI.MoveImageButton("ModAbout", PickerGap(4), iy + 60, "mods/wand_editor/files/gui/images/about.png", nil, ModAboutCB, ModAboutClickCB, nil, true)
	end

end

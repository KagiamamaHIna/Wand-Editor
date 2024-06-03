local UI
function GUIUpdata()
	if UI == nil then
		--初始化
		UI = dofile_once("mods/wand_editor/files/libs/gui.lua")
		dofile_once("mods/wand_editor/files/libs/fn.lua")
		dofile_once("data/scripts/lib/utilities.lua")

		local data = dofile_once("mods/wand_editor/files/gui/GetSpellData.lua")
		local spellData = data[1]
		local typelist = data[2]

        local function DarwSpellText(this, id, idata)
            local rightMargin = 70
            local function NewLine(str1, str2)
                local text = GameTextGetTranslatedOrNot(str1)
				local w = GuiGetTextDimensions(this.gui,text)
                GuiLayoutBeginHorizontal(this.gui, 0, 0, true, 2, -1)
				GuiText(this.gui, 0, 0, text)--耗蓝
				GuiText(this.gui, rightMargin - w, 0, str2)
				GuiLayoutEnd(this.gui)
			end
			
			local function NumToWithSignStr(num)
				local result
                if num >= 0 then
                    result = "+" .. tostring(num)
                else
                    result = tostring(num)
                end
				return result
			end

            GuiText(this.gui, 0, 0, GameTextGetTranslatedOrNot(idata.name))
			GuiColorSetForNextWidget(this.gui, 0.5, 0.5, 0.5, 1.0)
            GuiText(this.gui, 0, 0, id)
            GuiText(this.gui, 0, 0, GameTextGetTranslatedOrNot(idata.description))
            GuiColorSetForNextWidget(this.gui, 0.5, 0.5, 1.0, 1.0)
            GuiText(this.gui, 0, 0, SpellTypeEnumToStr(idata.type))
			
            GuiLayoutBeginVertical(this.gui, 0, 7, true) --垂直布局

			NewLine("$inventory_manadrain", tostring(idata.mana))--耗蓝
			if idata.max_uses and idata.max_uses ~= -1 then
				NewLine("使用次数", tostring(idata.max_uses))--使用次数
			end
			if idata.projComp and idata.projComp.damage ~= "0" then --如果有投射物伤害
				NewLine("$inventory_damage", tostring(tonumber(idata.projComp.damage) * 25))
			end
			
            if idata.projExplosion and idata.projExplosion ~= 0 then --如果有爆炸伤害
                NewLine("$inventory_dmg_explosion", tostring(math.floor(idata.projExplosion * 25)))
            end
			if idata.projExplosionRadius and idata.projExplosionRadius ~= 0 then --如果有爆炸半径
				NewLine("$inventory_explosion_radius", tostring(idata.projExplosionRadius))
			end
            if idata.projComp then
                for k, v in pairs(idata.projDmg) do --伤害参数
                    if v ~= 0 then
                        if k == "electricity" then
                            NewLine("$inventory_mod_damage_electric", tostring(v * 25))
                        else
                            NewLine("$inventory_dmg_" .. k, tostring(v * 25))
                        end
                    end
                end
                --散射(实在是看不出来哪里来的，先放着)

                --速度
                local speed_min = tonumber(idata.projComp.speed_min)
                local speed_max = tonumber(idata.projComp.speed_max)
                if (speed_min == speed_max) and speed_min ~= 0 and speed_max ~= 0 then
                    NewLine("$inventory_speed", tostring(speed_max))
                elseif speed_min ~= 0 and speed_max ~= 0 then
                    NewLine("$inventory_speed", tostring(speed_min) .. "~" .. tostring(speed_max))
                end
                if idata.lifetime then
                    local randomness = tonumber(idata.projComp.lifetime_randomness)
                    if randomness ~= 0 then
                        NewLine("存在时间",
                            tostring(idata.lifetime - randomness) .. "f~" .. tostring(idata.lifetime + randomness).."f")
                    else
                        NewLine("存在时间", idata.lifetime.."f")
                    end
                end
            end
			local SecondWithSign = Compose(NumToWithSignStr, tonumber, FrToSecondStr)
            if idata.c.fire_rate_wait ~= 0 then--施放延迟
                NewLine("$inventory_castdelay", SecondWithSign(idata.c.fire_rate_wait)  .. "s("..idata.c.fire_rate_wait.."f)" )
            end
            if idata.reload_time ~= 0 then --充能延迟
                NewLine("$inventory_rechargetime", SecondWithSign(idata.reload_time) .. "s("..idata.reload_time.."f)" )
            end
			
			GuiLayoutEnd(this.gui)
		end

		--获得玩家当前法杖数据
        local GetPlayerHeldWandData = Compose(GetWandData, GetEntityHeldWand, GetPlayer)
		local GetPlayerXY = Compose(EntityGetTransform, GetPlayer)
		local hasMove = false

		local OnMoveImage = false
		local MainButtonEnable = nil
		UI.TickEventFn["main"] = function(this)
			if not GameIsInventoryOpen() then
                GuiOptionsAdd(this.gui, GUI_OPTION.NoPositionTween) --你不要再飞啦！
				GuiZSetForNextWidget(this.gui, UI.GetZDeep())--设置深度，确保行为正确
				UI.MoveImagePicker("MainButton", 40, 50, 8, 0, "法杖编辑器", "mods/wand_editor/files/gui/images/menu.png",
					function(x, y)
						if MainButtonEnable then

						end
					end,
					function(left_click, right_click, x, y, enable)
						MainButtonEnable = enable
                        if left_click then
							OnMoveImage = not OnMoveImage
							
							--[[
                            local x, y = EntityGetTransform(GetPlayer())
                            local e = InitWand(GetWandData(GetEntityHeldWand(GetPlayer())), nil, x, y)]]
						end
                        if enable then --开启状态
                            local ZDeepest = UI.GetZDeep()
                            UI.ScrollContainer("TestScroll", 30, 60, 178, 170, nil, 0, 1.2)
                            for _, id in pairs(typelist[ACTION_TYPE_PROJECTILE]) do
                                UI.SetZDeep(UI.GetZDeep() + 3)--设置深度，确保行为正确
                                local sprite = spellData[id].sprite
                                UI.AddScrollImageItem("TestScroll", sprite, function()                 --绘制容器
                                    GuiZSetForNextWidget(this.gui, UI.GetZDeep())
                                    UI.MoveImageButton("__SPELL_" .. id, 0, 2, sprite, nil, function() --绘制法术图标
                                        if not hasMove then --法术悬浮窗绘制
                                            UI.tooltips(function()
                                                DarwSpellText(this, id, spellData[id])
                                            end, UI.GetZDeep() - 12, 7)
                                        end
                                    end, function(left_click, right_click, x, y) --点击效果
                                        local shift = InputIsKeyDown(Key_LSHIFT) or InputIsKeyDown(Key_RSHIFT)
                                        if left_click and shift then --shift+左键
                                            local inventory_full = EntityGetChildWithName(GetPlayer(), "inventory_full")
                                            if inventory_full then
                                                local px, py = GetPlayerXY()
                                                local spell = CreateItemActionEntity(id, px, py)
                                                EntitySetComponentsWithTagEnabled(spell, "enabled_in_world", false)
                                                EntityAddChild(inventory_full, spell)
                                                GamePrint(GameTextGetTranslatedOrNot(spellData[id].name), "已添加到物品栏中")
                                            end
                                        elseif left_click then --纯左键
                                            hasMove = true
                                            UI.TickEventFn["MoveSpellFn"] = function() --分离出一个事件，用于表示法术点击后的效果
                                                local click = InputIsMouseButtonDown(Mouse_right)
                                                if click then                          --右键取消
                                                    UI.OnMoveImage("MoveSpell", x, y, sprite, true)
                                                    UI.TickEventFn["MoveSpellFn"] = nil
                                                    hasMove = false
                                                    return
                                                end
                                                --绘制悬浮图标
                                                local status = UI.OnMoveImage("MoveSpell", x, y, sprite, nil, nil, ZDeepest-1,
                                                    function(movex, movey)
                                                        GuiZSetForNextWidget(this.gui, ZDeepest)
                                                        GuiImage(this.gui, UI.NewID("MoveSpell_BG"), movex - 2,
                                                            movey - 2, "data/ui_gfx/inventory/item_bg_projectile.png", 1,
                                                            1) --绘制背景
                                                    end)
                                                if not status then
                                                    UI.TickEventFn["MoveSpellFn"] = nil
                                                    local worldx, worldy = DEBUG_GetMouseWorld()
                                                    CreateItemActionEntity(id, worldx, worldy)
                                                    hasMove = false
                                                end
                                            end
                                        end
                                    end, nil, true)--最后两个参数是不始终调用点击回调和禁止移动

                                    --绘制背景，深度要控制好
                                    GuiZSetForNextWidget(this.gui, UI.GetZDeep() + 2)
                                    GuiImage(this.gui, UI.NewID("__SPELL_" .. id .. "_BG"), -20, 0,
                                        "data/ui_gfx/inventory/full_inventory_box.png", 1, 1)
                                    GuiZSetForNextWidget(this.gui, UI.GetZDeep() + 1)
                                    GuiImage(this.gui, UI.NewID("__SPELL_" .. id .. "_SPELLBG"), -22, 0,
                                        "data/ui_gfx/inventory/item_bg_projectile.png", 1, 1)
                                end)
                            end
							GuiZSetForNextWidget(this.gui, UI.GetZDeep()+ 1)--设置深度，确保行为正确
							UI.DrawScrollContainer("TestScroll")
						end
                        if OnMoveImage then
							--[[
						local status,x,y = UI.OnMoveImage("Test",0,0,"mods/wand_editor/files/gui/images/menu.png")
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

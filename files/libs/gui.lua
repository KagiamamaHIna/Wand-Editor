dofile_once("mods/wand_editor/files/libs/unsafe.lua")
dofile_once("mods/wand_editor/files/libs/fn.lua")
dofile_once("data/scripts/debug/keycodes.lua")
dofile_once("data/scripts/lib/utilities.lua")
local DefaultZDeep = -1250

local this = {
	private = {
        CompToPickerBool = {}, --用于存储按钮点击状态
		CompToPickerHoverBool = {},
        PickerList = {},--用于存储谁和谁是同一组的
		PickersCurrent = {},--用于存储谁是当前开启的
		TileTick = {},   --计划刻
		DestroyCallBack = {}, --销毁时的回调函数
		destroy = false, --销毁状态
        CompToID = {},   --组件转id
        TextInputIDtoStr = {}, --输入框id转其文本
        TextInputPos = {},     --输入框光标位置
        TextInputDrawPosTimer = nil,
        TextInputDrawPosHas = false;
		FirstEventFn = {}, --用于内部优先级最高的回调函数
		NextFrNoClick = false,
		NextFrClick = 0,
        Scale = nil,  --缩放参数
		ZDeep = DefaultZDeep,--深度
        IDMax = 0x7FFFFFFF, --下一个id分配的数字
        SliderData = {},
        SliderMax = {},
		SliderMin = {},
        ScrollData = {},
		ScrollItemData = {},
		ScrollAutoPos = {},
        HScrollData = {},
        HScrollSlider = {},--滑条数据，不重启游戏就是持久性的
        HScrollItemData = {}, --元素数据，用于判断位置是否上下溢出
		ConcatCache = {},
		ResetAllCanMove = nil,
		LastScreenWidth = -1,
		LastScreenHeight = -1,
	},
	public = {
		ScreenWidth = -1, --当前屏宽
        ScreenHeight = -1, --当前屏高
		MainTickFn = {},	--主要的刻事件，执行优先级更高
        TickEventFn = {},  --刻事件
		MiscEventFn = {},	--副要的刻事件，执行优先级最低
		UserData = {},
		gui = GuiCreate(), --gui userdata
	}
}

---@class Gui
---@field ScreenWidth integer
---@field ScreenHeight integer
---@field TickEventFn table
---@field MainTickFn table
---@field MiscEventFn table
---@field UserData table
---@field gui userdata
local UI = {}
setmetatable(UI, this)
this.__index = this.public

---将一个字符串拼接一下模组id的前缀然后返回
---@param str string
---@return string
local function ConcatModID(str)
	if this.private.ConcatCache[str] == nil then
        local result = ModID .. str
        return result
    else
		return this.private.ConcatCache[str]
	end
end

function UI.GetZDeep()
	return this.private.ZDeep
end

function UI.SetZDeep(z)
	this.private.ZDeep = z
end

local tooltipID = 0

local TooltipsCache = {}
---组件悬浮窗提示,应当在一个组件后面使用
---@param callback function
---@param z integer?
---@param xOffset integer?
---@param yOffset integer?
---@param NoYAutoMove boolean?
function UI.tooltips(callback, z, xOffset, yOffset, NoYAutoMove, YMoreOffset)
    local left_click, right_click, hover, x, y, width, height, draw_x, draw_y, draw_width, draw_height =
        GuiGetPreviousWidgetInfo(this.public.gui)
    if hover then
        local gui = this.public.gui
        if TooltipsCache[1] and TooltipsCache[2] then
            if TooltipsCache[1] ~= math.floor(x) or TooltipsCache[2] ~= math.floor(y) then
                if tooltipID < 31 then
                    tooltipID = tooltipID + 1
                else
                    tooltipID = 0
                end
            end
        end
        TooltipsCache[1] = math.floor(x)
        TooltipsCache[2] = math.floor(y)
        xOffset = Default(xOffset, 0)
        yOffset = Default(yOffset, 0)
        YMoreOffset = Default(YMoreOffset, 0)
        NoYAutoMove = Default(NoYAutoMove, false)
        z = Default(z, DefaultZDeep)
        if not NoYAutoMove and (draw_y > this.public.ScreenHeight * 0.5) then
            yOffset = yOffset - height + YMoreOffset
        end

        GuiZSet(gui, z)

        GuiIdPushString(gui, "TooltipsAlpha")
        GuiAnimateBegin(gui)
        GuiAnimateAlphaFadeIn(gui, tooltipID, 0.08, 0.1, false)
        GuiAnimateScaleIn(gui, tooltipID, 0.08, false)
        GuiIdPop(gui)

        GuiLayoutBeginLayer(gui)
        GuiLayoutBeginVertical(gui, (x + xOffset + width), (y + yOffset), true)
        GuiBeginAutoBox(gui)
        callback()
        GuiZSetForNextWidget(gui, z + 1)
        GuiEndAutoBoxNinePiece(gui)
        GuiLayoutEnd(gui)
        GuiLayoutEndLayer(gui)

        GuiAnimateEnd(gui)
    end
end

local BTooltipsNC = {}
---组件悬浮窗提示,应当在一个组件后面使用
---@param callback function
---@param z integer?
---@param xOffset integer?
---@param yOffset integer?
function UI.BetterTooltipsNoCenter(callback, z, xOffset, yOffset, leftMargin, rightMargin)
	local left_click, right_click, hover, x, y, width, height, draw_x, draw_y, draw_width, draw_height =
        GuiGetPreviousWidgetInfo(this.public.gui)
    if hover then
        local gui = this.public.gui
		xOffset = Default(xOffset, 0)
    	yOffset = Default(yOffset, 0)
    	leftMargin = Default(leftMargin, 10)
		rightMargin = Default(rightMargin, 10)
        z = Default(z, DefaultZDeep)
		
        GuiAnimateBegin(gui)
		GuiAnimateAlphaFadeIn(gui, UI.NewID("Alpha你肯定看不见我对吧"), 0, 0, false)
        GuiLayoutBeginLayer(gui)
        GuiLayoutBeginVertical(gui, (x + xOffset + width), y + yOffset, true)
		GuiBeginAutoBox(gui)
        callback()
		GuiZSetForNextWidget(gui, z + 1)
		GuiEndAutoBoxNinePiece(gui)
		GuiLayoutEnd(gui)
		GuiLayoutEndLayer(gui)
        GuiAnimateEnd(gui)
		
        local _,_,_,_,_,OffsetW,OffsetH = GuiGetPreviousWidgetInfo(gui)

		if BTooltipsNC[1] and BTooltipsNC[2] then
			if BTooltipsNC[1] ~= math.floor(x) or BTooltipsNC[2] ~= math.floor(y) then
				if tooltipID < 31 then
                    tooltipID = tooltipID + 1
                else
					tooltipID = 0
				end
			end
		end

		BTooltipsNC[1] = math.floor(x)
		BTooltipsNC[2] = math.floor(y)
		if x > this.public.ScreenWidth / 2 then
        	xOffset = -(OffsetW - 10 + xOffset)
        else
			xOffset = xOffset + width
		end

        if y + yOffset - 10 < 0 then --上超出
            yOffset = 0
        	y = 10
        end
		if y + yOffset + OffsetH + 5 > this.public.ScreenHeight then
			y = y + (this.public.ScreenHeight - (y + yOffset + OffsetH))
		end

        GuiZSet(gui, z)
		
        GuiAnimateBegin(gui)
		GuiIdPushString(gui,"BetterTooltipsNoCenterAlpha")
        GuiAnimateAlphaFadeIn(gui, tooltipID,0.08, 0.1, false)
        GuiAnimateScaleIn(gui, tooltipID, 0.08, false)
		GuiIdPop(gui)

        GuiLayoutBeginLayer(gui)
        GuiLayoutBeginVertical(gui, (x + xOffset), (y + yOffset), true)
		GuiBeginAutoBox(gui)
        callback()
		GuiZSetForNextWidget(gui, z + 1)
		GuiEndAutoBoxNinePiece(gui)
		GuiLayoutEnd(gui)
        GuiLayoutEndLayer(gui)

		GuiAnimateEnd(gui)
	end
end

OldGuiTooltip = GuiTooltip
--覆盖掉原版的函数
GuiTooltip = function(gui, text, description, xOffset)
	xOffset = Default(xOffset, 0)
	UI.BetterTooltipsNoCenter(function ()
        GuiText(this.public.gui, 0, 0, text)
		if description ~= nil and description ~= "" then
			GuiText(this.public.gui, 0, 0, description)
		end
	end,-3000,10 + xOffset)
end

local BTooltipCache = {}
---组件悬浮窗提示,应当在一个组件后面使用
---@param callback function
---@param z integer?
---@param xOffset integer?
---@param yOffset integer?
function UI.BetterTooltips(callback, z, xOffset, yOffset, leftMargin, rightMargin)
	local left_click, right_click, hover, x, y, width, height, draw_x, draw_y, draw_width, draw_height =
        GuiGetPreviousWidgetInfo(this.public.gui)
    if hover then
		local gui = this.public.gui
		xOffset = Default(xOffset, 0)
    	yOffset = Default(yOffset, 0)
    	leftMargin = Default(leftMargin, 10)
		rightMargin = Default(rightMargin, 10)
        z = Default(z, DefaultZDeep)

        GuiAnimateBegin(gui)
		GuiAnimateAlphaFadeIn(gui, UI.NewID("Alpha你肯定看不见我对吧"), 0, 0, false)
		GuiLayoutBeginLayer(gui)
        GuiLayoutBeginVertical(gui, x + xOffset, y + yOffset, true)
		GuiBeginAutoBox(gui)
        callback()
		GuiZSetForNextWidget(gui, z + 1)
		GuiEndAutoBoxNinePiece(gui)
		GuiLayoutEnd(gui)
		GuiLayoutEndLayer(gui)
        GuiAnimateEnd(gui)
		
        local _,_,_,_,_,OffsetW,OffsetH = GuiGetPreviousWidgetInfo(gui)
		if BTooltipCache[1] and BTooltipCache[2] then
			if BTooltipCache[1] ~= math.floor(x) or BTooltipCache[2] ~= math.floor(y) then
				if tooltipID < 31 then
                    tooltipID = tooltipID + 1
                else
					tooltipID = 0
				end
			end
		end
		BTooltipCache[1] = math.floor(x)
		BTooltipCache[2] = math.floor(y)

		xOffset = xOffset - OffsetW / 2 --居中
		if y + yOffset > this.public.ScreenHeight * 0.5 then--自动上下切换
			yOffset = -yOffset - OffsetH + height + 10
		end
        if y + yOffset - 10 < 0 then --上超出
    	    yOffset = 0
            y = 10
        end
		if y + yOffset + OffsetH + 5 > this.public.ScreenHeight then
			y = y + (this.public.ScreenHeight - (y + yOffset + OffsetH))
		end
		if x + OffsetW /2 + 10 + rightMargin > this.public.ScreenWidth then--右超出
			xOffset = -((x + OffsetW) - this.public.ScreenWidth + rightMargin)
		end
		if x + xOffset - leftMargin < 0 then--左超出
			x = leftMargin + 5
			xOffset = 0
		end
        GuiZSet(gui, z)

        GuiAnimateBegin(gui)

		GuiIdPushString(gui,"BetterTooltipsAlpha")
        GuiAnimateAlphaFadeIn(gui, tooltipID,0.08, 0.1, false)
		GuiAnimateScaleIn(gui, tooltipID,0.08, false)
		GuiIdPop(gui)

        GuiLayoutBeginLayer(gui)
        GuiLayoutBeginVertical(gui, (x + xOffset), (y + yOffset), true)
		GuiBeginAutoBox(gui)
        callback()
		GuiZSetForNextWidget(gui, z + 1)
		GuiEndAutoBoxNinePiece(gui)
		GuiLayoutEnd(gui)
        GuiLayoutEndLayer(gui)

		GuiAnimateEnd(gui)

	end
end

---新建id或返回已有id
---@param str string
---@return integer
function UI.NewID(str)
	str = ConcatModID(str) --这个id很重要，最好不能重复
	if this.private.CompToID[str] == nil then
		local result = this.private.IDMax
		this.private.CompToID[str] = result
		this.private.IDMax = this.private.IDMax - 1
		return result
	else
		return this.private.CompToID[str]
	end
end

---返回已有id
---@param str string
---@return integer
function UI.GetID(str)
	return this.private.CompToID[str]
end

---简化版
---@param id string
---@param x number
---@param y number
---@param image string
---@param AlwaysCallBack function|nil
---@param HoverUseCallBack function|nil
---@param ClickCallBack function|nil
---@param AlwaysCBClick boolean?
---@param noMove boolean?
---@return boolean
function UI.MoveImageButton(id, x, y, image, AlwaysCallBack, HoverUseCallBack, ClickCallBack, AlwaysCBClick, noMove)
    local function imageButton(gui, numId, InputX, InputY)
		return GuiImageButton(gui, numId, InputX, InputY, "", image)
	end
	return UI.CanMove(id, x, y, imageButton, AlwaysCallBack, HoverUseCallBack, ClickCallBack, image, AlwaysCBClick, nil, noMove)
end

---绘制一个跟随鼠标移动的图片
---@param id string
---@param x number
---@param y number
---@param image string
---@param isClose boolean?
---@param scale number?
---@param ZDeep number?
---@param ClickAble boolean|nil
---@param AlwaysCallBack function?
---@return boolean|nil
---@return number|nil
---@return number|nil
function UI.OnMoveImage(id, x, y, image, isClose, scale, ZDeep, ClickAble, AlwaysCallBack)
	isClose = Default(isClose, false)
	scale = Default(scale, 1)
    local CanMoveStr = ConcatModID("on_move_" .. id)
	if isClose then--这个参数是代表要关闭这个悬浮窗的
        ModSettingSet(CanMoveStr, false) --提前设置
		--暂停判断一段时间
		this.private.NextFrNoClick = true
		this.private.NextFrClick = 12
		this.private.FirstEventFn["NextFrNoClick"] = function()
			if this.private.NextFrClick == 0 then
				this.private.NextFrNoClick = false
                this.private.FirstEventFn["NextFrNoClick"] = nil
				return
			end
			this.private.NextFrClick = this.private.NextFrClick - 1
		end
		return--所以退出
	end
	ModSettingSet(CanMoveStr, true) --提前设置

    local function imageButton(gui, numId, InputX, InputY)
		if ZDeep == nil then
			this.private.ZDeep = this.private.ZDeep + 1
			GuiZSetForNextWidget(this.public.gui, this.private.ZDeep)
            GuiImage(gui, numId, InputX, InputY, image, 1, scale)
        else
            GuiZSetForNextWidget(this.public.gui, ZDeep)
			GuiImage(gui, numId, InputX, InputY, image, 1, scale)
		end
	end
	local ResultX = x
	local ResultY = y
    local function GetXY(InputResultX, InputResultY)
        ResultX = InputResultX
        ResultY = InputResultY
        if AlwaysCallBack ~= nil then
            AlwaysCallBack(ResultX, ResultY)
        end
    end
	local inputClickAble
	if type(ClickAble) == "boolean" then
        inputClickAble = ClickAble
		ClickAble = true
	end
	return UI.CanMove(id, x, y, imageButton, GetXY, nil, nil, image, true, true, nil, scale, ClickAble, inputClickAble), ResultX, ResultY
end

function UI.GetPickerStatus(id)
    local newid = ConcatModID(id)
	if this.private.CompToPickerBool[newid] == nil and ModSettingGet(newid) ~= nil then
		this.private.CompToPickerBool[newid] = ModSettingGet(newid)
	end
	return this.private.CompToPickerBool[newid]
end

function UI.SetPickerEnable(id, enable)
    local newid = ConcatModID(id)
    this.private.CompToPickerBool[newid] = enable
	if ModSettingGet(newid) ~= nil then
		ModSettingSet(newid, this.private.CompToPickerBool[newid])
	end
end

function UI.GetPickerHover(id)
    local newid = ConcatModID(id)
	local status = this.private.CompToPickerHoverBool[newid]
    if status == nil then
        return false
    end
	return status
end

---自带开关显示的按钮
---@param id string
---@param x number
---@param y number
---@param mx number
---@param my number
---@param Content string
---@param image string
---@param StatusCustomText table?
---@param ClickCallBack function?
---@param OpenImage string?
---@param SemiTransparent boolean?
---@param SaveModSetting boolean?
---@param noMove boolean?
---@param NoYAutoMove boolean?
---@return boolean
function UI.MoveImagePicker(id, x, y, mx, my, Content, image, StatusCustomText, ClickCallBack, OpenImage, SemiTransparent, SaveModSetting, noMove, NoYAutoMove)
    local newid = ConcatModID(id)
	NoYAutoMove = Default(NoYAutoMove, false)
    if SaveModSetting and this.private.CompToPickerBool[newid] == nil then
        if ModSettingGet(newid) == nil then
            ModSettingSet(newid, false)
        end
        this.private.CompToPickerBool[newid] = ModSettingGet(newid) --通过模组设置初始化
    elseif not SaveModSetting and ModSettingGet(newid) then
		ModSettingRemove(newid)
    end

    if this.private.PickerList[newid] then
		local key = this.private.PickerList[newid]
        if this.private.PickersCurrent[key] == newid then
            this.private.CompToPickerBool[newid] = true
        else
            this.private.CompToPickerBool[newid] = false
        end
		if SaveModSetting then
            ModSettingSet(newid, this.private.CompToPickerBool[newid])
        elseif not SaveModSetting and ModSettingGet(newid) ~= nil then--移除
			ModSettingRemove(newid)
		end
	end
    if this.private.CompToPickerBool[newid] == nil then
        this.private.CompToPickerBool[newid] = false
    end
	if StatusCustomText then
		if this.private.CompToPickerBool[newid] then
			Content = GameTextGetTranslatedOrNot(StatusCustomText[1]) .. Content
		else
			Content = GameTextGetTranslatedOrNot(StatusCustomText[2]) .. Content
		end
    else
		if this.private.CompToPickerBool[newid] then
			Content = GameTextGetTranslatedOrNot("$wand_editor_picker_close") .. Content
		else
			Content = GameTextGetTranslatedOrNot("$wand_editor_picker_open") .. Content
		end
	end

    local function Hover()
        local _, _, hover = GuiGetPreviousWidgetInfo(this.public.gui)
        this.private.CompToPickerHoverBool[newid] = hover
        UI.BetterTooltipsNoCenter(function()
            GuiText(this.public.gui, 0, 0, Content)
            if id == "MainButton" then
                GuiColorSetForNextWidget(this.public.gui, 0.5, 0.5, 0.5, 1.0)
				if Cpp.PathExists("mods/wand_editor/cache/UpdateFlag") and this.public.UserData["UpdateDataVer"] then
					GuiText(this.public.gui, 0, 2, ModVersion.."->"..this.public.UserData["UpdateDataVer"]..GameTextGet("$wand_editor_auto_update_done"))
                else
					GuiText(this.public.gui, 0, 2, ModVersion)
				end
                GuiLayoutAddVerticalSpacing(this.public.gui, 2)
                GuiZSet(this.public.gui, this.private.ZDeep)
            end
            if not noMove then
                local CTRL = InputIsKeyDown(Key_LCTRL) or InputIsKeyDown(Key_RCTRL)
                GuiZSetForNextWidget(this.public.gui, DefaultZDeep - 114514)
                if CTRL then
                    GuiColorSetForNextWidget(this.public.gui, 0.5, 0.5, 0.5, 1.0)
                    GuiText(this.public.gui, 0, 0, GameTextGetTranslatedOrNot("$wand_editor_picker_desc"))
                else
                    GuiColorSetForNextWidget(this.public.gui, 0.5, 0.5, 0.5, 1.0)
                    GuiText(this.public.gui, 0, 0, GameTextGetTranslatedOrNot("$wand_editor_picker_more"))
                end
            end
        end, DefaultZDeep - 100, mx, my)
    end
    local function Click(left_click, right_click, ix, iy)
        if ClickCallBack ~= nil then
            ClickCallBack(left_click, right_click, ix, iy, this.private.CompToPickerBool[newid]) --额外输入一个参数5，代表当前按钮启用状态
        end
        if left_click and this.private.PickerList[newid] then
			local key = this.private.PickerList[newid]
            if this.private.PickersCurrent[key] == newid then
                this.private.PickersCurrent[key] = nil
            else
                this.private.PickersCurrent[key] = newid
            end
			GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", GameGetCameraPos())
		elseif left_click then
            this.private.CompToPickerBool[newid] = not this.private.CompToPickerBool[newid]
			ModSettingSet(newid, this.private.CompToPickerBool[newid])
			GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", GameGetCameraPos())
        end
    end
    if OpenImage and this.private.CompToPickerBool[newid] then
        image = OpenImage
    end
    if SemiTransparent and (not this.private.CompToPickerBool[newid]) then
        GuiOptionsAddForNextWidget(this.public.gui, GUI_OPTION.DrawSemiTransparent)
    end
    GuiZSetForNextWidget(this.public.gui, this.private.ZDeep)
	this.private.ZDeep = this.private.ZDeep + 1
    local result = { UI.MoveImageButton(id, x, y, image, nil, Hover, Click, nil, noMove) }
	return  unpack(result)
end

---输入一堆Picker id，代表他们启动状态是同一组的
---@param ... string
function UI.PickerEnableList(...)
    local t = { ... }
	for i=1,#t do--初始化处理
		t[i] = ConcatModID(t[i])
	end
	for _,v in pairs(t)do
        this.private.PickerList[v] = t
	end
end

function UI.GetNoMoveBool()
	return this.private.NextFrNoClick
end

function UI.ResetAllCanMove()
	this.private.ResetAllCanMove = {}
end

---一个较为通用的让控件可以移动并设置的函数
---@param id string
---@param s_x number
---@param s_y number
---@param ButtonCallBack function
---@param AlwaysCallBack function|nil
---@param HoverUseCallBack function|nil
---@param ClickCallBack function|nil
---@param image string
---@param AlwaysCBClick boolean? AlwaysCBClick = false
---@param noSetting boolean? noSetting = false
---@param noMove boolean? noMove = false
---@param scale number? scale = 1
---@return boolean 返回是否移动的状态
function UI.CanMove(id, s_x, s_y, ButtonCallBack, AlwaysCallBack, HoverUseCallBack, ClickCallBack, image, AlwaysCBClick,
					noSetting, noMove, scale, IsNoListenerClick, ClickAble)
	local true_s_x = s_x
	local true_s_y = s_y
	local newid = ConcatModID(id)
	noSetting = Default(noSetting, false)
    AlwaysCBClick = Default(AlwaysCBClick, false)
	noMove = Default(noMove, false)
    scale = Default(scale, 1)
	IsNoListenerClick = Default(IsNoListenerClick, false)
	local numID = UI.NewID(id)
	local Xname = newid .. "x"
	local Yname = newid .. "y"
    local CanMoveStr = ConcatModID("on_move_" .. id)
    if this.private.ResetAllCanMove ~= nil and this.private.ResetAllCanMove[newid] == nil then
		ModSettingRemove(Xname) --恢复默认设置
		ModSettingRemove(Yname)
		this.private.ResetAllCanMove[newid] = true
	end
    if not ModSettingGet(CanMoveStr) or noMove then --非移动状态
        if not noSetting and not noMove then
            if ModSettingGet(Xname) ~= nil then  --没有设置就使用默认坐标
                s_x = ModSettingGet(Xname)
            end
            if ModSettingGet(Yname) ~= nil then
                s_y = ModSettingGet(Yname)
            end
        end

        local hasMove = ModSettingGet(ModID .. "hasButtonMove")                    --其他按钮移动时，将无法触发按钮事件
        local left_click, right_click = ButtonCallBack(this.public.gui, numID, s_x, s_y) --调用回调参数，用于新建想要的控件
        local shift = InputIsKeyDown(Key_LSHIFT) or InputIsKeyDown(Key_RSHIFT)
        if shift and left_click and (not this.private.NextFrNoClick) and not noMove then --两者同时按下
            --开始移动
            ModSettingSet(ModID .. "hasButtonMove", true)
            ModSettingSet(CanMoveStr, true)
        elseif (not hasMove) or AlwaysCBClick then --其他按钮没有移动的时候
            if right_click and not noMove then --如果按下右键，且是非移动的
                ModSettingRemove(Xname)        --恢复默认设置
                ModSettingRemove(Yname)
            end
            if HoverUseCallBack ~= nil then
                HoverUseCallBack()
            end
            if AlwaysCallBack ~= nil then
                AlwaysCallBack(s_x, s_y)
            end
            if ClickCallBack ~= nil and ((not this.private.NextFrNoClick) or AlwaysCBClick) then
                ClickCallBack(left_click, right_click, s_x, s_y)
            elseif ClickCallBack ~= nil and this.private.NextFrNoClick then --绘制但不判断
                ClickCallBack(false, false, s_x, s_y)
            end
        end
        return ModSettingGet(CanMoveStr)
    end
	if not noSetting then
		ModSettingSet(ModID .. "hasButtonMove", true)
	end
	--移动中
    local mx, my = InputGetMousePosOnScreen()
	mx = mx / this.private.Scale
	my = my / this.private.Scale
	if image then --如果有图片
		local w, h = GuiGetImageDimensions(this.public.gui, image, scale)
		mx = mx - w / 2
		my = my - h / 2
	end
	local click = ClickAble--如果点击了
	if not IsNoListenerClick then
		click = InputIsMouseButtonDown(Mouse_left)
	end
	if click then
		ModSettingSet(CanMoveStr, false)          --设置移动状态
		ModSettingSet(ModID .. "hasButtonMove", false)
		if not noSetting then
			ModSettingSet(Xname, mx)
			ModSettingSet(Yname, my)
		end

		--暂停判断一段时间
		this.private.NextFrNoClick = true
		this.private.NextFrClick = 10
		this.private.FirstEventFn["NextFrNoClick"] = function()
			if this.private.NextFrClick == 0 then
				this.private.NextFrNoClick = false
                this.private.FirstEventFn["NextFrNoClick"] = nil
				return
			end
			this.private.NextFrClick = this.private.NextFrClick - 1
		end
	end

	ButtonCallBack(this.public.gui, numID, mx, my)
	if AlwaysCallBack ~= nil then
		AlwaysCallBack(mx, my)
	end
	return ModSettingGet(CanMoveStr)
end

function UI.ScrollContainer(id, x, y, w, h, margin_x, margin_y, scale)
	margin_x = Default(margin_x, 2)
    margin_y = Default(margin_y, 2)
	scale = Default(scale, 1)
	local newid = ConcatModID(id)
	if this.private.ScrollData[newid] == nil then--判断是否有数据
        this.private.ScrollData[newid] = { id = id, x = x, y = y, w = w, h = h, margin_x = margin_x, margin_y = margin_y,scale = scale }--初始化数据
        this.private.ScrollData[newid].Item = {}
        this.private.ScrollData[newid].Any = {}
		this.private.ScrollData[newid].ItemK = 1
		this.private.ScrollData[newid].AnyK = 1
	end
end

---设置参数
---@param id string
---@param x number|nil?
---@param y number|nil?
---@param w number|nil?
---@param h number|nil?
---@param margin_x number|nil?
---@param margin_y number|nil?
function UI.SetScrollContainer(id, x, y, w, h, margin_x, margin_y)
	local newid = ConcatModID(id)
	if this.private.ScrollData[newid] then--判断是否有数据
        if x then
            this.private.ScrollData[newid].x = x
        end
        if y then
            this.private.ScrollData[newid].y = y
        end
        if w then
            this.private.ScrollData[newid].w = w
        end
        if h then
            this.private.ScrollData[newid].h = h
        end
        if margin_x then
            this.private.ScrollData[newid].margin_x = margin_x
        end
		if margin_y then
			this.private.ScrollData[newid].margin_y = margin_y
		end
	end
end

---为一个指定id的Scroll控件添加任意位置的项目
---@param id string
---@param callback function
function UI.AddAnywhereItem(id, callback)
	local newid = ConcatModID(id)
    if this.private.ScrollData[newid] then --判断是否有数据
		this.private.ScrollData[newid].Any[this.private.ScrollData[newid].AnyK] = callback
		this.private.ScrollData[newid].AnyK = this.private.ScrollData[newid].AnyK + 1
	end
end

---为一个指定id的Scroll控件添加图片项目
---@param id string
---@param image string
---@param callback function
function UI.AddScrollImageItem(id, image, callback)
	local newid = ConcatModID(id)
    if this.private.ScrollData[newid] then --判断是否有数据
		this.private.ScrollData[newid].Item[this.private.ScrollData[newid].ItemK] = {CB = callback,image = image}
		this.private.ScrollData[newid].ItemK = this.private.ScrollData[newid].ItemK + 1
	end
end

---为一个指定id的Scroll控件添加文本项目
---@param id string
---@param text string
---@param callback? function|nil
function UI.AddScrollTextItem(id, text, callback)
	local newid = ConcatModID(id)
    if this.private.ScrollData[newid] then --判断是否有数据
		this.private.ScrollData[newid].Item[this.private.ScrollData[newid].ItemK] = {CB = callback,text = text}
		this.private.ScrollData[newid].ItemK = this.private.ScrollData[newid].ItemK + 1
	end
end

---获得Item表
---@param id string
---@return table|nil
function UI.GetScrollItemList(id)
	local newid = ConcatModID(id)
    if this.private.ScrollData[newid] then --判断是否有数据
        return this.private.ScrollData[newid].Item
    end
end

---@param id string
---@return number|nil
function UI.GetScrollWidth(id)
    local newid = ConcatModID(id)
	if this.private.ScrollAutoPos[newid] then
		return this.private.ScrollAutoPos[newid].w
	end
    if this.private.ScrollData[newid] then --判断是否有数据
        return this.private.ScrollData[newid].w
    end
end

---@param id string
---@return number|nil
function UI.GetScrollHeight(id)
    local newid = ConcatModID(id)
	if this.private.ScrollAutoPos[newid] then
		return this.private.ScrollAutoPos[newid].h
	end
    if this.private.ScrollData[newid] then --判断是否有数据
        return this.private.ScrollData[newid].h
    end
end

---@param id string
---@return number|nil
function UI.GetScrollX(id)
	local newid = ConcatModID(id)
    if this.private.ScrollData[newid] then --判断是否有数据
        return this.private.ScrollData[newid].x
    end
end

---@param id string
---@return number|nil
function UI.GetScrollY(id)
	local newid = ConcatModID(id)
    if this.private.ScrollData[newid] then --判断是否有数据
        return this.private.ScrollData[newid].y
    end
end

---@param id string
---@return number|nil
function UI.GetScrollMX(id)
    local newid = ConcatModID(id)
    if this.private.ScrollData[newid] then --判断是否有数据
        return this.private.ScrollData[newid].margin_x
    end
end

---@param id string
---@return number|nil
function UI.GetScrollMY(id)
	local newid = ConcatModID(id)
    if this.private.ScrollData[newid] then --判断是否有数据
        return this.private.ScrollData[newid].margin_y
    end
end

function UI.ScrollCB(id, f)
	local newid = ConcatModID(id)
	this.private.ScrollData[newid].f = f
end

---根据指定id开始绘制Scroll控件
---@param id string
---@param IsBlock boolean?
---@param IsAutoBox boolean?
function UI.DrawScrollContainer(id, IsBlock, IsAutoBox)
    local newid = ConcatModID(id)
	IsBlock = Default(IsBlock, true)
    if this.private.ScrollData[newid] then --如果有数据
        local x = this.private.ScrollData[newid].x
		local y = this.private.ScrollData[newid].y
        local w = this.private.ScrollData[newid].w
		local h = this.private.ScrollData[newid].h
        local function IsHover(posx, posy)
            if posx > x and posx <= x + w + 5 + this.private.ScrollData[newid].margin_x and posy > y and posy <= y + h + this.private.ScrollData[newid].margin_y then
                return true
            end
            return false
        end

		local mx, my = InputGetMousePosOnScreen()
		mx = mx / this.private.Scale
        my = my / this.private.Scale
        local hover = IsHover(mx, my)
        if hover and IsBlock then
			GuiAnimateBegin(this.public.gui)
            GuiAnimateAlphaFadeIn(this.public.gui, UI.NewID("Alpha你肯定看不见我对吧的另一个动画"), 0, 0, false)

			GuiLayoutBeginLayer(this.public.gui)
            GuiZSetForNextWidget(this.public.gui, this.private.ZDeep - 1)
			
			GuiOptionsAddForNextWidget(this.public.gui, GUI_OPTION.AlwaysClickable)
            local autow, autoh
			if this.private.ScrollAutoPos[newid] then--好像不生效，不管了反正也用不到，先不修了
                autow = this.private.ScrollAutoPos[newid].w
                autoh = this.private.ScrollAutoPos[newid].h
            else
				autow = this.private.ScrollData[newid].w
				autoh = this.private.ScrollData[newid].h
			end
            GuiBeginScrollContainer(this.public.gui, UI.NewID("你看不见的框"), this.private.ScrollData[newid].x,
            this.private.ScrollData[newid].y, autow, autoh, true, this.private.ScrollData[newid].margin_x,
                this.private.ScrollData[newid].margin_y)
			
            GuiEndScrollContainer(this.public.gui)

			GuiLayoutEndLayer(this.public.gui)
			GuiAnimateEnd(this.public.gui)
        end
		
        GuiLayoutBeginLayer(this.public.gui) --先开启这个
		local thisDrawIsOffsetInit = false
        if IsAutoBox then
            if this.private.ScrollAutoPos[newid] == nil or this.private.ScrollAutoPos[newid].LastScale ~= this.private.Scale then
                this.private.ScrollAutoPos[newid] = {}
                this.private.ScrollAutoPos[newid].LastScale = this.private.Scale
                thisDrawIsOffsetInit = true
				GuiAnimateBegin(this.public.gui)
				GuiAnimateAlphaFadeIn(this.public.gui, UI.NewID("Alpha你肯定看不见我对吧的另一个动画之自动偏移需要计算因而被隐藏了"), 0, 0, false)
            end
            local offsetX = this.private.ScrollAutoPos[newid].x
            local offsetY = this.private.ScrollAutoPos[newid].y
			if offsetX and offsetY then
				offsetX = offsetX - this.private.ScrollData[newid].x
				offsetY = offsetY - this.private.ScrollData[newid].y
            else
                offsetX = 0
				offsetY = 0
			end
			GuiLayoutBeginVertical(this.public.gui, this.private.ScrollData[newid].x - offsetX, this.private.ScrollData[newid].y - offsetY, true)
			GuiBeginAutoBox(this.public.gui)
        else
			GuiZSetForNextWidget(this.public.gui, this.private.ZDeep)
			GuiBeginScrollContainer(this.public.gui, UI.NewID(id), this.private.ScrollData[newid].x,
            this.private.ScrollData[newid].y, this.private.ScrollData[newid].w, this.private.ScrollData[newid].h,
			true,this.private.ScrollData[newid].margin_x, this.private.ScrollData[newid].margin_y)
		end

		for _,v in pairs(this.private.ScrollData[newid].Any)do
			v()
		end

        GuiLayoutBeginVertical(this.public.gui, 0, 0, true) --垂直布局
		if this.private.ScrollData[newid].f then
			this.private.ScrollData[newid].f()
		end
        local ElemWidth = 0
        local RowCount = 0
		GuiLayoutBeginHorizontal(this.public.gui, 0 , 0, true)--横向自动分布 
        for _, v in pairs(this.private.ScrollData[newid].Item) do
			RowCount = RowCount + 1
            if v.text then --如果是文本
                local width = GuiGetTextDimensions(this.public.gui, v.text, this.private.ScrollData[newid].scale)
                ElemWidth = ElemWidth + width
            else --不是文本就是图片
                local width = GuiGetImageDimensions(this.public.gui, v.image, this.private.ScrollData[newid].scale)
                ElemWidth = ElemWidth + width
            end
			if RowCount == 1 or ElemWidth < this.private.ScrollData[newid].w then--如果是行的第一个元素，或者总元素宽小于控件宽的时候
				if v.CB then
					v.CB()
				end
            else --重置
                RowCount = 1
				if v.CB then
					v.CB()
				end
                ElemWidth = 0
                GuiLayoutEnd(this.public.gui)--结束这次绘制
				GuiLayoutBeginHorizontal(this.public.gui, 0 , 0, true)--横向自动分布。开始下次绘制
			end
		end
        GuiLayoutEnd(this.public.gui)
		
        GuiLayoutEnd(this.public.gui)
		if IsAutoBox then--移位问题，没解决
			GuiZSetForNextWidget(this.public.gui, this.private.ZDeep + 100)
            GuiEndAutoBoxNinePiece(this.public.gui, this.private.ScrollData[newid].margin_x,this.private.ScrollData[newid].w,this.private.ScrollData[newid].h)
            if this.private.ScrollAutoPos[newid].x == nil and this.private.ScrollAutoPos[newid].y == nil then
                local _, _, _, autox, autoy, width, height = GuiGetPreviousWidgetInfo(this.public.gui)
                this.private.ScrollAutoPos[newid].x = autox
                this.private.ScrollAutoPos[newid].y = autoy
                this.private.ScrollAutoPos[newid].h = height
                this.private.ScrollAutoPos[newid].w = width
            end
            GuiLayoutEnd(this.public.gui)
			if thisDrawIsOffsetInit then
				GuiAnimateEnd(this.public.gui)
			end
		else
			GuiEndScrollContainer(this.public.gui)
		end
		GuiLayoutEndLayer(this.public.gui)
	end
end

-- 分隔符集合
local separators = { [' '] = true, ['.'] = true, ['-'] = true , ['_'] = true}

-- 判断字符是否为分隔符
local function is_separator(char)
    return separators[char] ~= nil
end

--缝缝补补的逻辑乱的我都不想看
local function jump_to_next_position(text, cursor_pos)
    local length = Cpp.UTF8StringSize(text)
    local pos = cursor_pos
	--判断是否需要跳过
	if is_separator(Cpp.UTF8StringSub(text, pos+1, pos+1)) or is_separator(Cpp.UTF8StringSub(text, pos, pos)) then
		pos = pos + 1
	end
    --如果有就跳过当前可能的分隔符，然后就是位置
	local JumpFlag = false
    while pos <= length and is_separator(Cpp.UTF8StringSub(text, pos, pos)) do
        pos = pos + 1
        JumpFlag = true
    end
	if JumpFlag then
		return pos - 1
	end
    --找到下一个分隔符，返回前一个位置
    while pos <= length do
        local char = Cpp.UTF8StringSub(text, pos, pos)
        if is_separator(char) then
            return pos - 1
        end
        pos = pos + 1
    end

    --如果没有更多位置，返回文本结尾
    return length
end

local function jump_to_previous_position(text, cursor_pos)
    local pos = cursor_pos
    --判断是否需要跳过
	local JumpSeparator = false
	if is_separator(Cpp.UTF8StringSub(text, pos, pos)) then
		pos = pos - 1
		JumpSeparator = true
	end
    --如果有就跳过当前可能的分隔符，然后就是位置
	local JumpFlag = false
    while pos > 1 and is_separator(Cpp.UTF8StringSub(text, pos, pos)) do
        pos = pos - 1
		JumpFlag = true
    end
    if JumpFlag then
        return pos
	elseif JumpSeparator then
		return pos
    end
    --找到上一个分隔符，返回下一个位置
    while pos > 0 do
        local char = Cpp.UTF8StringSub(text, pos, pos)
        if is_separator(char) then
            return pos
        end
        pos = pos - 1
    end

    --如果到达文本开头，返回位置0
    return 0
end

---文本输入框，会保证文本不会超出限制
---@param id string
---@param x number
---@param y number
---@param w number
---@param l number
---@param str string? str=""
---@param allowed_characters string?
---@return string
function UI.TextInput(id, x, y, w, l, str, allowed_characters)
    local Remove1Char = function(InputStr, pos)
        local utf8Size = Cpp.UTF8StringSize(InputStr)
		if pos > utf8Size or pos < 1 then--检查越界
			return InputStr
		end
        local FirstStr = ""
        if pos - 1 >= 1 and utf8Size > pos - 1 then
            FirstStr = Cpp.UTF8StringSub(InputStr, 1, pos - 1)
        end
		local SecondStr = ""
        if pos + 1 <= utf8Size and pos + 1 > 0 then
            SecondStr = Cpp.UTF8StringSub(InputStr, pos + 1, utf8Size)
        end
        if FirstStr == "" and SecondStr == "" and (utf8Size ~= 1 and pos ~= 1) then
            return InputStr
        elseif utf8Size == 1 and pos == 1 then --单独删除字符的特判
            return ""
        end
        return Cpp.ConcatStr(FirstStr, SecondStr)
    end
    local Add1Char = function(InputStr, pos, char)
        local utf8Size = Cpp.UTF8StringSize(InputStr)
        local FirstStr = ""
        if pos > 0 and utf8Size >= pos then
            FirstStr = Cpp.UTF8StringSub(InputStr, 1, pos)
        end
        local SecondStr = ""
        if pos + 1 <= utf8Size and pos + 1 > 0 then
            SecondStr = Cpp.UTF8StringSub(InputStr, pos + 1, Cpp.UTF8StringSize(InputStr))
        end
        return Cpp.ConcatStr(FirstStr, char, SecondStr)
    end

    str = Default(str, "")
	allowed_characters = Default(allowed_characters, "")
    local newid = ConcatModID(id)
    if this.private.TextInputIDtoStr[newid] == nil then--初始化中
        this.private.TextInputIDtoStr[newid] = { s_str = str, str = str }
    end
	if this.private.TextInputPos[newid] == nil then
        this.private.TextInputPos[newid] = Cpp.UTF8StringSize(this.private.TextInputIDtoStr[newid].str)
		this.private.TextInputDrawPosTimer = 60--顺带重置这个
    elseif this.private.TextInputPos[newid] < 0 then--这个也是防止越界的
        this.private.TextInputPos[newid] = 0
	end
	local newStr = this.private.TextInputIDtoStr[newid].str

	GuiOptionsAddForNextWidget(this.public.gui,GUI_OPTION.NonInteractive)
    GuiTextInput(this.public.gui, UI.NewID(id), x, y, this.private.TextInputIDtoStr[newid].str, w, l, allowed_characters)

    local _, _, TXHover, TIx, TIy, TXWidth, height = GuiGetPreviousWidgetInfo(this.public.gui)	--绘制光标
    this.private.TextInputDrawPosHas = this.private.TextInputDrawPosHas or TXHover
    if this.private.TextInputIDtoStr[newid].SetStr ~= nil then--设置文本，并检查超出部分
        local SetStr = this.private.TextInputIDtoStr[newid].SetStr
        local strWidth = GuiGetTextDimensions(this.public.gui, SetStr, 1)
        local Size = Cpp.UTF8StringSize(SetStr)
        local LastChar = ""
        if Size > 1 then
            LastChar = Cpp.UTF8StringSub(SetStr, Size - 1, Size)
        end
        local LastCharWidth = GuiGetTextDimensions(this.public.gui, LastChar, 1)
        while strWidth + 4 > TXWidth - LastCharWidth do --自动裁剪超出文本框的文本
            SetStr = Cpp.UTF8StringSub(SetStr, 1, Cpp.UTF8StringSize(SetStr) - 1)
            Size = Cpp.UTF8StringSize(SetStr)
            LastChar = ""
            if Size > 1 then
                LastChar = Cpp.UTF8StringSub(SetStr, Size - 1, Size)
            end
            LastCharWidth = GuiGetTextDimensions(this.public.gui, LastChar, 1)
            strWidth = GuiGetTextDimensions(this.public.gui, SetStr, 1)
        end
        newStr = SetStr
        this.private.TextInputIDtoStr[newid].SetStr = nil
		this.private.TextInputPos[newid] = Cpp.UTF8StringSize(newStr)--设置光标位置
    end
	
	--[[
    local HasMoreSpaceWidth = GuiGetTextDimensions(this.public.gui, "| |", 1)--因为有时候空格不会渲染长度，所以用一种奇特但有效的方式兼容
    local MoreCharWidth = GuiGetTextDimensions(this.public.gui, "|", 1)
    SpaceWidth = HasMoreSpaceWidth - MoreCharWidth * 2
	]]
    if TXHover then
        if this.private.TextInputDrawPosTimer == nil or this.private.TextInputDrawPosTimer <= 0 then
            this.private.TextInputDrawPosTimer = 60
        elseif this.private.TextInputDrawPosTimer > 0 then
            this.private.TextInputDrawPosTimer = this.private.TextInputDrawPosTimer - 1
        end
        if this.private.TextInputPos[newid] > Cpp.UTF8StringSize(newStr) then --防止越界
            this.private.TextInputPos[newid] = Cpp.UTF8StringSize(newStr)
        end
		local CalcStr = Cpp.UTF8StringSub(newStr,1,this.private.TextInputPos[newid])
		local StrWidth = GuiGetTextDimensions(this.public.gui, CalcStr, 1)

        if this.private.TextInputDrawPosTimer > 30 then--可以使得悬浮在上面的时候立刻绘制一段时间光标作为提示

            --local GreyWidth = GuiGetImageDimensions(this.public.gui, "mods/wand_editor/files/gui/images/grey_1px.png", 1)
            local MoreHeight = height - math.floor(height)
            local MaxI = 1
            for i = 1, math.floor(height) - 4 do
                MaxI = i
                GuiZSetForNextWidget(this.public.gui, UI.GetZDeep() - 100)
                GuiOptionsAddForNextWidget(this.public.gui, GUI_OPTION.Layout_NoLayouting)
                GuiOptionsAddForNextWidget(this.public.gui, GUI_OPTION.NonInteractive)
                GuiImage(UI.gui, UI.NewID("NoDarwGreyPixel" .. tostring(i)), TIx + StrWidth + 2, TIy + i + 1, "mods/wand_editor/files/gui/images/grey_1px.png", 1, 1)
			end
            if MoreHeight > 0 then--高度不为整数的时候补齐提示光标
                MoreHeight = MoreHeight / 2
                GuiZSetForNextWidget(this.public.gui, UI.GetZDeep() - 100)
                GuiOptionsAddForNextWidget(this.public.gui, GUI_OPTION.Layout_NoLayouting)
                GuiOptionsAddForNextWidget(this.public.gui, GUI_OPTION.NonInteractive)
                GuiImage(UI.gui, UI.NewID("NoDarwGreyPixelLow"), TIx + StrWidth + 2, TIy + 2 - MoreHeight, "mods/wand_editor/files/gui/images/grey_1px.png", 1, 1)
                
                GuiZSetForNextWidget(this.public.gui, UI.GetZDeep() - 100)
                GuiOptionsAddForNextWidget(this.public.gui, GUI_OPTION.Layout_NoLayouting)
                GuiOptionsAddForNextWidget(this.public.gui, GUI_OPTION.NonInteractive)
                GuiImage(UI.gui, UI.NewID("NoDarwGreyPixelHigh"), TIx + StrWidth + 2, TIy + MaxI + 2 - MoreHeight, "mods/wand_editor/files/gui/images/grey_1px.png", 1, 1)
            end
        end
    end

	GuiAnimateBegin(this.public.gui)
    GuiAnimateAlphaFadeIn(this.public.gui, UI.NewID("Alpha你肯定看不见我对吧的另一个动画" .. id), 0, 0, false)
	GuiOptionsAddForNextWidget(this.public.gui,GUI_OPTION.Layout_NoLayouting)
    local newChar = GuiTextInput(this.public.gui, UI.NewID(id .. "NoDarwTextInput"), TIx,TIy, "", w, l, allowed_characters)
    GuiAnimateEnd(this.public.gui)

    if newChar ~= "" and (Cpp.UTF8StringSize(newStr) + Cpp.UTF8StringSize(newChar) < l + 1 or l == -1) then--新增字符操作，也要重置光标显示
        local SrcNewStr = newStr
        newStr = Add1Char(newStr, this.private.TextInputPos[newid], newChar)
        local strWidth = GuiGetTextDimensions(this.public.gui, newStr, 1)
        local newCharWidth = GuiGetTextDimensions(this.public.gui, newChar, 1)
        if strWidth + 4 < TXWidth - newCharWidth then--自动判断是否超出文本框
            this.private.TextInputPos[newid] = this.private.TextInputPos[newid] + Cpp.UTF8StringSize(newChar)
			this.private.TextInputDrawPosTimer = 60
        else
            newStr = SrcNewStr
        end
    end

    if this.private.TextInputIDtoStr[newid].str ~= newStr and this.private.TextInputIDtoStr[newid].DelFr ~= 0 then --如果新文本和旧文本不匹配，那么就重新设置
        this.private.TextInputIDtoStr[newid].str = newStr
    end
    local _, _, hover = GuiGetPreviousWidgetInfo(this.public.gui)--获得当前控件是否悬浮
    if hover then
        if this.private.TextInputIDtoStr[newid].ActiveItem == nil then
            this.private.TextInputIDtoStr[newid].ActiveItem = GetActiveItem()
        end
        --屏蔽按键输入
        BlockAllInput()
        if this.private.TextInputIDtoStr[newid].ActiveItem then --屏蔽切换物品
            UI.OnceCallOnExecute(function()
                SetActiveItem(this.private.TextInputIDtoStr[newid].ActiveItem)
            end)
        end
        if this.private.TextInputIDtoStr[newid].DelFr == nil then --如果在悬浮，就分配一个删除用的帧检测时间
            this.private.TextInputIDtoStr[newid].DelFr = 30
        else
            if InputIsKeyDown(Key_BACKSPACE) or InputIsKeyDown(Key_DELETE) then --如果按了退格键
                if this.private.TextInputIDtoStr[newid].DelFr == 30 then        --移除时也要重置光标显示
                    local input = this.private.TextInputIDtoStr[newid].str
                    if InputIsKeyDown(Key_DELETE) then
                        this.private.TextInputIDtoStr[newid].str = Remove1Char(input,
                            this.private.TextInputPos[newid] + 1)
                    else
                        this.private.TextInputIDtoStr[newid].str = Remove1Char(input, this.private.TextInputPos[newid])
                        this.private.TextInputPos[newid] = this.private.TextInputPos[newid] - 1
                    end
                    this.private.TextInputDrawPosTimer = 60
                end
                if this.private.TextInputIDtoStr[newid].DelFr ~= 0 then
                    this.private.TextInputIDtoStr[newid].DelFr = this.private.TextInputIDtoStr[newid].DelFr - 1
                else --如果到了0
                    local input = this.private.TextInputIDtoStr[newid].str
                    if InputIsKeyDown(Key_DELETE) then
                        this.private.TextInputIDtoStr[newid].str = Remove1Char(input,
                            this.private.TextInputPos[newid] + 1)
                    else
                        this.private.TextInputIDtoStr[newid].str = Remove1Char(input, this.private.TextInputPos[newid])
                        this.private.TextInputPos[newid] = this.private.TextInputPos[newid] - 1
                    end
                    this.private.TextInputDrawPosTimer = 60
                end
            else
                this.private.TextInputIDtoStr[newid].DelFr = 30 --如果不按退格键就重置时间
            end
        end
    elseif this.private.TextInputIDtoStr[newid].DelFr then --如果未悬浮就设为空
        RestoreInput()
        this.private.TextInputIDtoStr[newid].ActiveItem = nil
        this.private.TextInputIDtoStr[newid].DelFr = nil
    end
	
	local MovePos = function ()
        if InputIsKeyDown(Key_LCTRL) or InputIsKeyDown(Key_RCTRL) then
			local input = this.private.TextInputIDtoStr[newid].str
			if InputIsKeyDown(Key_LEFT) then
				this.private.TextInputPos[newid] = jump_to_previous_position(input, this.private.TextInputPos[newid])
			else
				this.private.TextInputPos[newid] = jump_to_next_position(input, this.private.TextInputPos[newid])
			end
		else
			if InputIsKeyDown(Key_LEFT) then
				this.private.TextInputPos[newid] = this.private.TextInputPos[newid] - 1
			else
				this.private.TextInputPos[newid] = this.private.TextInputPos[newid] + 1
			end
		end
	end

	if hover then
        if this.private.TextInputIDtoStr[newid].PosFr == nil then --如果在悬浮，就分配一个移动光标用的帧检测时间
            this.private.TextInputIDtoStr[newid].PosFr = 30
        end
		if InputIsKeyDown(Key_LEFT) or InputIsKeyDown(Key_RIGHT) then --如果按了方向键
			if this.private.TextInputIDtoStr[newid].PosFr == 30 then        --移动时也要重置光标显示
				MovePos()
				this.private.TextInputDrawPosTimer = 60
			end
			if this.private.TextInputIDtoStr[newid].PosFr ~= 0 then
				this.private.TextInputIDtoStr[newid].PosFr = this.private.TextInputIDtoStr[newid].PosFr - 1
			else --如果到了0
				this.private.TextInputIDtoStr[newid].PosFr = 2--间隔两帧
				MovePos()
				this.private.TextInputDrawPosTimer = 60
			end
		else--如果不按就重置时间
			this.private.TextInputIDtoStr[newid].PosFr = 30
		end
    elseif this.private.TextInputIDtoStr[newid].PosFr then--如果未悬浮就设为空
		this.private.TextInputIDtoStr[newid].PosFr = nil
	end
    --点击文本切换光标位置
    if hover and InputIsMouseButtonJustDown(Mouse_left) and this.private.TextInputIDtoStr[newid].str ~= "" then --如果点击了且是悬浮状态
        local mx, my = InputGetMousePosOnScreen()
        mx = mx / this.private.Scale
        my = my / this.private.Scale
        local input = this.private.TextInputIDtoStr[newid].str
        local CharTable = Cpp.UTF8StringChars(input)
        local ConcatChars = ""
        local SwitchPos = 0
        local StrWidth
        for i = 1, #CharTable do
            ConcatChars = ConcatChars .. CharTable[i]                                   --拼接用于计算字符串长度
            StrWidth = GuiGetTextDimensions(this.public.gui, ConcatChars, 1) + 2        --2是偏移量
            if mx > TIx and mx < TIx + StrWidth then --判断是否在范围内，都悬浮状态了，不用判断y轴
                SwitchPos = i
                --print("Result:",i)
                break --及时退出
            end
        end
        if SwitchPos > 0 then --有结果
            local CharLen = GuiGetTextDimensions(this.public.gui, CharTable[SwitchPos], 1)
            if mx < TIx + StrWidth - CharLen + CharLen / 2 then
                this.private.TextInputPos[newid] = SwitchPos - 1
            else
                this.private.TextInputPos[newid] = SwitchPos
            end
            this.private.TextInputDrawPosTimer = 60 --切换位置时重置光标绘制
        elseif mx < TXWidth + TIx and mx > TIx then
            this.private.TextInputPos[newid] = nil --重置到最前面
            this.private.TextInputDrawPosTimer = 60
        end
    end
	if hover and InputIsKeyDown(Key_HOME) or InputIsKeyDown(Key_END) then--home和end键的实现
        if InputIsKeyDown(Key_HOME) then
            this.private.TextInputPos[newid] = 0
        else
            this.private.TextInputPos[newid] = nil --重置到最前面
        end
		this.private.TextInputDrawPosTimer = 60
	end
	return this.private.TextInputIDtoStr[newid].str
end

---获取文本
---@param id string
---@return string|nil
function UI.GetInputText(id)
    local newid = ConcatModID(id)
	if this.private.TextInputIDtoStr[newid] ~= nil then
        return this.private.TextInputIDtoStr[newid].str
    end
end

---设置文本
---@param id string
---@param str string
function UI.SetInputText(id, str)
    local newid = ConcatModID(id)
    if this.private.TextInputIDtoStr[newid] ~= nil then
		this.private.TextInputIDtoStr[newid].SetStr = str
    end
end

---恢复文本
---@param id string
function UI.TextInputRestore(id)
	local newid = ConcatModID(id)
    if this.private.TextInputIDtoStr[newid] ~= nil then
		this.private.TextInputPos[newid] = nil--重置光标位置
        this.private.TextInputIDtoStr[newid].str = this.private.TextInputIDtoStr[newid].s_str
    end
end

---获得checkbox状态
---@param id string
---@return boolean
function UI.GetCheckboxEnable(id)
    local newid = ConcatModID(id)
    local CheckboxEnableKey = newid .. "_enabled"
	return ModSettingGet(CheckboxEnableKey)
end

---设置checkbox状态
---@param id string
---@param enable boolean
function UI.SetCheckboxEnable(id, enable)
	local newid = ConcatModID(id)
    local CheckboxEnableKey = newid .. "_enabled"
	ModSettingSet(CheckboxEnableKey, enable)
end

---checkbox
---@param id string
---@param x number
---@param y number
---@param text string
---@param RightOrLeft boolean? RightOrLeft = true 默认右
---@param HoverUseCallBack function?
---@param TextHoverUse function?
---@param StatusCallBack function?
function UI.checkbox(id, x, y, text, RightOrLeft, HoverUseCallBack, TextHoverUse, StatusCallBack)
    local newid = ConcatModID(id)
	RightOrLeft = Default(RightOrLeft, true)
    local CheckboxEnableKey = newid .. "_enabled"
	local Margin = 10
    local TextX = x + Margin
    if not RightOrLeft then
        local w = GuiGetTextDimensions(this.public.gui, text)
        TextX = x - w - 2
    end
    local checkboxImage
    if ModSettingGet(CheckboxEnableKey) then
        checkboxImage = "mods/wand_editor/files/gui/images/checkbox_fill.png"
    elseif ModSettingGet(CheckboxEnableKey) == nil then --初始化
        ModSettingSet(CheckboxEnableKey, false)
        checkboxImage = "mods/wand_editor/files/gui/images/checkbox.png"
    else
        checkboxImage = "mods/wand_editor/files/gui/images/checkbox.png"
    end
    GuiZSetForNextWidget(this.public.gui, this.private.ZDeep)
	this.private.ZDeep = this.private.ZDeep + 1
    local left_click = GuiImageButton(this.public.gui, UI.NewID(id), x, y, "", checkboxImage)
	if HoverUseCallBack ~= nil then
		HoverUseCallBack(x, y)
	end
    if left_click then --如果点击了
        GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", GameGetCameraPos())
        ModSettingSet(CheckboxEnableKey, not ModSettingGet(CheckboxEnableKey))
    end
    local status = ModSettingGet(CheckboxEnableKey)
    GuiOptionsAddForNextWidget(this.public.gui, GUI_OPTION.NoSound)
	
	GuiZSetForNextWidget(this.public.gui, this.private.ZDeep - 1)
	this.private.ZDeep = this.private.ZDeep + 1
    GuiButton(this.public.gui, UI.NewID(id .. "TEXT"), TextX, y - 1, text) --绘制文本

	if TextHoverUse ~= nil then
		GuiZSetForNextWidget(this.public.gui, this.private.ZDeep)
		this.private.ZDeep = this.private.ZDeep + 1
		TextHoverUse(TextX, y)
	end
    if StatusCallBack ~= nil then
		GuiZSetForNextWidget(this.public.gui, this.private.ZDeep)
		this.private.ZDeep = this.private.ZDeep + 1
		StatusCallBack(status)
	end
end

---滑条
---@param id string
---@param x number
---@param y number
---@param text string
---@param value_min number
---@param value_max number
---@param value_default number
---@param value_display_multiplier number
---@param value_formatting string
---@param width number
---@return number
function UI.Slider(id,x,y,text,value_min, value_max, value_default, value_display_multiplier, value_formatting, width)
    local newid = ConcatModID(id)
    if this.private.SliderData[newid] == nil or value_min > this.private.SliderData[newid] or this.private.SliderData[newid] > value_max then
        this.private.SliderData[newid] = value_default
    end
    this.private.SliderMax[newid] = value_max
	this.private.SliderMin[newid] = value_min
    this.private.SliderData[newid] = GuiSlider(this.public.gui, UI.NewID(id), x, y, text, this.private.SliderData[newid],
        value_min, value_max, value_default, value_display_multiplier, value_formatting, width)

	return this.private.SliderData[newid]
end

---获取滑条的值
---@param id string
---@return number
function UI.GetSliderValue(id)
    local newid = ConcatModID(id)
	return this.private.SliderData[newid]
end

---设置滑条的值
---@param id string
---@param value number
function UI.SetSliderValue(id, value)
    local newid = ConcatModID(id)
    if this.private.SliderData[newid] then
		if value <= this.private.SliderMax[newid] and value >= this.private.SliderMin[newid] then
			this.private.SliderData[newid] = value
        else
			if value <= this.private.SliderMax[newid] then
                this.private.SliderData[newid] = this.private.SliderMin[newid]
            else
				this.private.SliderData[newid] = this.private.SliderMax[newid]
			end
		end
	end
end

---横向分布容器
---@param id string
---@param x number
---@param y number
---@param w number
---@param h number
---@param DarwContainer boolean?
---@param margin_x number?
---@param margin_y number?
function UI.HorizontalScroll(id, x, y, w, h, DarwContainer, margin_x, margin_y)
	DarwContainer = Default(DarwContainer, true)
	margin_x = Default(margin_x, 2)
    margin_y = Default(margin_y, 2)
	local newid = ConcatModID(id)
    if this.private.HScrollData[newid] == nil then                                                                         --判断是否有数据
        this.private.HScrollData[newid] = { id = id, x = x, y = y, w = w, h = h, margin_x = margin_x, margin_y = margin_y, DarwContainer = DarwContainer } --初始化数据
        this.private.HScrollData[newid].Item = {}
		this.private.HScrollData[newid].ItemK = 1
    end
	if this.private.HScrollSlider[newid] == nil then
		this.private.HScrollSlider[newid] = {}
	end
end

---为横向分布容器增加新元素
---@param id string
---@param callback function
function UI.AddHScrollItem(id, callback)
	local newid = ConcatModID(id)
    if this.private.HScrollData[newid] then --判断是否有数据
        this.private.HScrollData[newid].Item[this.private.HScrollData[newid].ItemK] = callback
		this.private.HScrollData[newid].ItemK = this.private.HScrollData[newid].ItemK + 1
	end
end

function UI.GetHScrollWidth(id)
	local newid = ConcatModID(id)
    if this.private.HScrollSlider[newid] then --判断是否有数据
        return this.private.HScrollSlider[newid].width or 0
    end
end

function UI.ResetHScrollSlider(id)
	local newid = ConcatModID(id)
    if this.private.HScrollSlider[newid] then --判断是否有数据
        this.private.HScrollSlider[newid] = {}
    end
end

---绘制横向分布容器
---@param id string
function UI.DarwHorizontalScroll(id)
    local newid = ConcatModID(id)
    local SliderValue = this.private.HScrollSlider[newid].value
    local ScrollWidth = this.private.HScrollSlider[newid].width
    local LastHover = this.private.HScrollSlider[newid].hover
    SliderValue = Default(SliderValue, 0.00)
    ScrollWidth = Default(ScrollWidth, 0)
	LastHover = Default(LastHover, false)
    if this.private.HScrollData[newid] then  --如果有数据
		local x = this.private.HScrollData[newid].x
        local y = this.private.HScrollData[newid].y
		local w = this.private.HScrollData[newid].w
        local h = this.private.HScrollData[newid].h
		local DarwContainer = this.private.HScrollData[newid].DarwContainer

        local function IsHover(posx, posy)
            if posx > x and posx <= x + w and posy > y and posy <= y + h then
                return true
            end
            return false
        end
		
        GuiLayoutBeginLayer(this.public.gui) --先开启这个

        GuiZSetForNextWidget(this.public.gui, this.private.ZDeep + 1)
		if DarwContainer then
			GuiBeginScrollContainer(this.public.gui, UI.NewID(id), x, y, w, h, true,
				this.private.HScrollData[newid].margin_x, this.private.HScrollData[newid].margin_y
        	)	
		end

        local margin_x = (w - ScrollWidth) * SliderValue             --计算偏移
		if DarwContainer then
            GuiLayoutBeginHorizontal(this.public.gui, margin_x, 0, true)
        else
			GuiLayoutBeginHorizontal(this.public.gui, x + margin_x, y, true) --横向布局
		end
        for k, v in pairs(this.private.HScrollData[newid].Item) do
            local flag, _, _, ItemX, _, ItemW = v(this.private.HScrollItemData[k]) --传入一个参数，如果参数是真，那么就代表没有超出位置，如果是nil，那么代表超出位置
			if flag == nil then
				_, _, _, ItemX, _, ItemW = GuiGetPreviousWidgetInfo(this.public.gui)
			end
			if DarwContainer then
				if ItemX + ItemW/2 > x and ItemX + ItemW/2 <= x + w then--判断x轴有没有超出位置
					this.private.HScrollItemData[k] = true
				else
					this.private.HScrollItemData[k] = nil --减少内存占用（，有可能
				end
			end

            local ItemRightX = ItemX - margin_x - x + math.floor(ItemW / 2) + this.private.HScrollData[newid].margin_x --计算正确的位置
			if ItemRightX > ScrollWidth then
                ScrollWidth = ItemRightX + math.floor(ItemW / 2) + this.private.HScrollData[newid].margin_x
			end
		end
		GuiLayoutEnd(this.public.gui)
        if DarwContainer then
			GuiEndScrollContainer(this.public.gui)
		end
        GuiLayoutEndLayer(this.public.gui)

		local hover = false
		--鼠标位置
		local mx, my = InputGetMousePosOnScreen()
		mx = mx / this.private.Scale
        my = my / this.private.Scale
		hover =  IsHover(mx, my)
        this.private.HScrollSlider[newid].width = math.floor(ScrollWidth) --取整减小误差
        if ScrollWidth > w then
            GuiZSetForNextWidget(this.public.gui, this.private.ZDeep)
            if not LastHover then
				GuiOptionsAddForNextWidget(this.public.gui, GUI_OPTION.DrawSemiTransparent)
			end
            this.private.HScrollSlider[newid].value = GuiSlider(this.public.gui, UI.NewID("slider" .. id), x - 4, h + y +
                1, "", SliderValue, 0, 1, 0.00, 0, " ", w + 3.5)
            local _, _, SliderHover = GuiGetPreviousWidgetInfo(this.public.gui)
			hover = hover or SliderHover
            this.private.HScrollSlider[newid].hover = hover
			local function MoveSlider()
				local left = InputIsKeyDown(Key_KP_MINUS) or InputIsKeyDown(Key_LEFT) or InputIsKeyDown(Key_MINUS)
                local right = InputIsKeyDown(Key_KP_PLUS) or InputIsKeyDown(Key_RIGHT) or InputIsKeyDown(Key_EQUALS)
                local num = 0.01
				if InputIsKeyDown(Key_LSHIFT) or InputIsKeyDown(Key_RSHIFT) then--按下shift一次移动更多
					num = num * 10
				end
				if left then
					this.private.HScrollSlider[newid].value = math.max(this.private.HScrollSlider[newid].value - num, 0)
				elseif right then
					this.private.HScrollSlider[newid].value = math.min(this.private.HScrollSlider[newid].value + num, 1)
				end
			end
			if hover then
                local hasPush = InputIsKeyDown(Key_KP_PLUS) or InputIsKeyDown(Key_KP_MINUS) or InputIsKeyDown(Key_LEFT) or
                	InputIsKeyDown(Key_RIGHT) or InputIsKeyDown(Key_MINUS) or InputIsKeyDown(Key_EQUALS)
				
				if this.private.HScrollSlider[newid].PushFr == nil then --如果在悬浮，就分配一个帧检测时间
					this.private.HScrollSlider[newid].PushFr = 30
				else
                    if hasPush then --如果按了
						if this.private.HScrollSlider[newid].PushFr == 30 then--按的第一下
							MoveSlider()
						end
						if this.private.HScrollSlider[newid].PushFr ~= 0 then
							this.private.HScrollSlider[newid].PushFr = this.private.HScrollSlider[newid].PushFr - 1
						else --如果到了0
							MoveSlider()
						end
					else
						this.private.HScrollSlider[newid].PushFr = 30 --如果不按退格键就重置时间
					end
				end
			elseif this.private.HScrollSlider[newid].PushFr then --如果未悬浮就设为空
				this.private.HScrollSlider[newid].PushFr = nil
			end
        else
			this.private.HScrollSlider[newid].value = 0
		end
		this.private.ZDeep = this.private.ZDeep + 1
	end
end

---返回一个缩放参数，代表相对ui的位置与实际ui位置的倍率
---@return number
function UI.GetScale()
	return this.private.Scale
end

---添加计划刻事件
---@param fn function
function UI.OnceCallOnExecute(fn)
	table.insert(this.private.TileTick, fn)
end

---关闭UI
function UI.Destroy()
	this.private.destroy = true
end

---当ui关闭时执行
---@param fn string
function UI.OnDestroy(fn)
	table.insert(this.private.DestroyCallBack, fn)
end

---派发消息
function UI.DispatchMessage()
    GuiStartFrame(this.public.gui)
    GuiOptionsAdd(this.public.gui, GUI_OPTION.NoPositionTween) --你不要再飞啦！
	this.public.ScreenWidth, this.public.ScreenHeight = GuiGetScreenDimensions(this.public.gui)
	if this.public.ScreenWidth ~= this.private.LastScreenWidth or this.public.ScreenHeight ~= this.private.LastScreenHeight then
        local GetScaleGui = GuiCreate()
        local SrcW, SrcH = GuiGetScreenDimensions(GetScaleGui)
        GuiDestroy(GetScaleGui)
        this.private.Scale = SrcH / this.public.ScreenHeight
        this.private.LastScreenWidth = this.public.ScreenWidth
		this.private.LastScreenHeight = this.public.ScreenHeight
	end
	
    for _, fn in pairs(this.private.FirstEventFn) do
        if type(fn) == "function" then
            fn(UI)
        end
    end

	local max = table.maxn(this.private.TileTick)
    if max >= 0 then
        for i = max, 1, -1 do
            local fn = this.private.TileTick[i]
            if type(fn) == "function" then
                fn(UI)
            end
            this.private.TileTick[i] = nil
        end
    end
	for key, fn in pairs(this.public.MainTickFn) do
        if type(fn) == "function" then
            fn(UI)
        end
	end
    for key, fn in pairs(this.public.TickEventFn) do
        if type(fn) == "function" then
            fn(UI)
        end
    end
    for key, fn in pairs(this.public.MiscEventFn) do
        if type(fn) == "function" then
            fn(UI)
        end
    end

    if this.private.destroy then
        GuiDestroy(this.public.gui)
        this.private.gui = nil
        for _, fn in pairs(this.private.DestroyCallBack) do
            if type(fn) == "function" then
                fn(UI)
            end
        end
    end
    if next(this.private.ScrollData) then --如果表有数据
        this.private.ScrollData = {}      --清空数据		
    end
    if next(this.private.HScrollData) then --如果表有数据
        this.private.HScrollData = {}     --清空数据        
    end
    if not this.private.TextInputDrawPosHas then--如果没有悬浮的就清空数据
        this.private.TextInputDrawPosTimer = nil
    end
    this.private.TextInputDrawPosHas = false
    this.private.ZDeep = DefaultZDeep
end

return UI

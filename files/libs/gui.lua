dofile_once("mods/wand_editor/files/libs/unsafe.lua")
dofile_once("mods/wand_editor/files/libs/fn.lua")
dofile_once("data/scripts/debug/keycodes.lua")
local Nxml = dofile_once("mods/wand_editor/files/libs/nxml.lua")

local this = {
	private = {
		CompToPickerBool = {}, --用于存储按钮点击状态
		TileTick = {},   --计划刻
		DestroyCallBack = {}, --销毁时的回调函数
		destroy = false, --销毁状态
        CompToID = {},   --组件转id
		TextInputIDtoStr = {}, --输入框id转其文本
		FirstEventFn = {}, --用于内部优先级最高的回调函数
		NextFrNoClick = false,
		NextFrClick = 0,
        Scale = nil,  --缩放参数
		ZDeep = -10000,
		IDMax = 0x7FFFFFFF, --下一个id分配的数字
		ScrollData = {},
	},
	public = {
		ScreenWidth = -1, --当前屏宽
		ScreenHeight = -1, --当前屏高
		TickEventFn = {}, --刻事件
		gui = GuiCreate(), --gui userdata
	}
}

local UI = {}
setmetatable(UI, this)
this.__index = this.public

---将一个字符串拼接一下模组id的前缀然后返回
---@param str string
---@return string
local function ConcatModID(str)
	return ModID .. str
end

function UI.GetZDeep()
	return this.private.ZDeep
end

function UI.SetZDeep(z)
	this.private.ZDeep = z
end

---组件悬浮窗提示,应当在一个组件后面使用
---@param callback function
---@param z integer?
---@param xOffset integer?
---@param yOffset integer?
---@param NoYAutoMove boolean?
function UI.tooltips(callback, z, xOffset, yOffset, NoYAutoMove)
	local gui = this.public.gui
	xOffset = Default(xOffset, 0)
    yOffset = Default(yOffset, 0)
	NoYAutoMove = Default(NoYAutoMove, false)
	z = Default(z, this.private.ZDeep)
	local left_click, right_click, hover, x, y, width, height, draw_x, draw_y, draw_width, draw_height =
		GuiGetPreviousWidgetInfo(gui)
	if not NoYAutoMove and (draw_y > this.public.ScreenHeight * 0.5) then
		yOffset = yOffset - height
	end

	if hover then
		GuiZSet(gui, z)
		GuiLayoutBeginLayer(gui)
        GuiLayoutBeginVertical(gui, (x + xOffset + width), (y + yOffset), true)
		GuiBeginAutoBox(gui)
		if callback ~= nil then callback() end
		GuiZSetForNextWidget(gui, z + 1)
		GuiEndAutoBoxNinePiece(gui)
		GuiLayoutEnd(gui)
		GuiLayoutEndLayer(gui)
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
---@param AlwaysCBClick boolean
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
---@param isClose boolean
---@param image string
---@param scale number?
---@param ZDeep number?
---@param AlwaysCallBack function?
---@return boolean|nil
---@return number|nil
---@return number|nil
function UI.OnMoveImage(id, x, y, image, isClose, scale, ZDeep, AlwaysCallBack)
	isClose = Default(isClose, false)
	scale = Default(scale, 1)
    local CanMoveStr = "on_move_" .. id
	if isClose then--这个参数是代表要关闭这个悬浮窗的
        ModSettingSet(CanMoveStr, false) --提前设置
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
	return UI.CanMove(id, x, y, imageButton, GetXY, nil, nil, image, true, nil, nil, scale), ResultX, ResultY
end

---自带开关显示的按钮
---@param id string
---@param x number
---@param y number
---@param mx number
---@param my number
---@param Content string
---@param image string
---@param AlwaysCallBack function?
---@param ClickCallBack function?
---@param OpenImage string?
---@param AlwaysCBClick boolean
---@return boolean
function UI.MoveImagePicker(id, x, y, mx, my, Content, image, AlwaysCallBack, ClickCallBack, OpenImage, AlwaysCBClick, noMove)
	local newid = ConcatModID(id)
	if this.private.CompToPickerBool[newid] == nil then
		this.private.CompToPickerBool[newid] = false
	end
	if this.private.CompToPickerBool[newid] then
		Content = GameTextGetTranslatedOrNot("$wand_editor_picker_close") .. Content
	else
		Content = GameTextGetTranslatedOrNot("$wand_editor_picker_open") .. Content
	end
	local TheZ = this.private.ZDeep
    local function Hover()
        UI.tooltips(function()
            GuiText(this.public.gui, 0, 0, Content)
            if not noMove then
                local CTRL = InputIsKeyDown(Key_LCTRL) or InputIsKeyDown(Key_RCTRL)
                if CTRL then
                    GuiColorSetForNextWidget(this.public.gui, 0.5, 0.5, 0.5, 1.0)
                    GuiText(this.public.gui, 0, 0, GameTextGetTranslatedOrNot("$wand_editor_picker_desc"))
                else
                    GuiColorSetForNextWidget(this.public.gui, 0.5, 0.5, 0.5, 1.0)
                    GuiText(this.public.gui, 0, 0, GameTextGetTranslatedOrNot("$wand_editor_picker_more"))
                end
            end
        end, TheZ, mx, my)
    end
    local function Click(left_click, right_click, ix, iy)
        if ClickCallBack ~= nil then
            ClickCallBack(left_click, right_click, ix, iy, this.private.CompToPickerBool[newid]) --额外输入一个参数5，代表当前按钮启用状态
        end
        if left_click then
            this.private.CompToPickerBool[newid] = not this.private.CompToPickerBool[newid]
			GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", GameGetCameraPos())
        end
    end
	if OpenImage and this.private.CompToPickerBool[newid] then
		image = OpenImage
	end
    local result = { UI.MoveImageButton(id, x, y, image, AlwaysCallBack, Hover, Click, AlwaysCBClick, noMove) }
	return  unpack(result)
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
					noSetting, noMove, scale)
	local true_s_x = s_x
	local true_s_y = s_y
	local newid = ConcatModID(id)
	local moveid = "move_" .. id
	noSetting = Default(noSetting, false)
    AlwaysCBClick = Default(AlwaysCBClick, false)
	noMove = Default(noMove, false)
	scale = Default(scale, 1)
	local numID = UI.NewID(id)
	local Xname = newid .. "x"
	local Yname = newid .. "y"
	local CanMoveStr = "on_move_" .. id
	if not ModSettingGet(CanMoveStr) or noMove then --非移动状态
		if not noSetting and not noMove then
			if ModSettingGet(Xname) == nil then
				ModSettingSet(Xname, s_x)
			else
				s_x = ModSettingGet(Xname)
			end
			if ModSettingGet(Yname) == nil then
				ModSettingSet(Yname, s_y)
			else
				s_y = ModSettingGet(Yname)
			end
		end

		local hasMove = ModSettingGet(ModID .. "hasButtonMove")                    --其他按钮移动时，将无法触发按钮事件
		local left_click, right_click = ButtonCallBack(this.public.gui, numID, s_x, s_y) --调用回调参数，用于新建想要的控件
		local shift = InputIsKeyDown(Key_LSHIFT) or InputIsKeyDown(Key_RSHIFT)
		if shift and left_click and (not this.private.NextFrNoClick) and not noMove then          --两者同时按下
			--开始移动
			ModSettingSet(ModID .. "hasButtonMove", true)
			ModSettingSet(CanMoveStr, true)
		elseif (not hasMove) or AlwaysCBClick then --其他按钮没有移动的时候
            if right_click and not noMove then --如果按下右键，且是非移动的
                ModSettingSet(Xname, true_s_x) --恢复默认设置
                ModSettingSet(Yname, true_s_y)
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
	--移动中
	local mx, my = InputGetMousePosOnScreen()
	mx = mx / this.private.Scale
	my = my / this.private.Scale
	if image then --如果有图片
		local w, h = GuiGetImageDimensions(this.public.gui, image, scale)
		mx = mx - w / 2
		my = my - h / 2
	end

	local click = InputIsMouseButtonDown(Mouse_left) --如果点击了
	if click then
		ModSettingSet(CanMoveStr, false)          --设置移动状态
		ModSettingSet(ModID .. "hasButtonMove", false)
		if not noSetting then
			ModSettingSet(Xname, mx)
			ModSettingSet(Yname, my)
		end

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
	end
end

---设置参数
---@param id string
---@param x number|nil?
---@param y number|nil?
---@param w number|nil?
---@param h number|nil?
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
		table.insert(this.private.ScrollData[newid].Any, callback)
	end
end

---为一个指定id的Scroll控件添加图片项目
---@param id string
---@param image string
---@param callback function
function UI.AddScrollImageItem(id, image, callback)
	local newid = ConcatModID(id)
    if this.private.ScrollData[newid] then --判断是否有数据
		table.insert(this.private.ScrollData[newid].Item, {CB = callback,image = image})
	end
end

---为一个指定id的Scroll控件添加文本项目
---@param id string
---@param text string
---@param callback? function|nil
function UI.AddScrollTextItem(id, text, callback)
	local newid = ConcatModID(id)
	if this.private.ScrollData[newid] then--判断是否有数据
		table.insert(this.private.ScrollData[newid].Item, {CB = callback,text = text})
	end
end

---获得Item表
---@param id string
---@return table|nil
function GetScrollItemList(id)
	local newid = ConcatModID(id)
    if this.private.ScrollData[newid] then --判断是否有数据
        return this.private.ScrollData[newid].Item
    end
end

function UI.ScrollCB(id, f)
	local newid = ConcatModID(id)
	this.private.ScrollData[newid].f = f
end

---根据指定id开始绘制Scroll控件
---@param id string
function UI.DrawScrollContainer(id)
	local newid = ConcatModID(id)
	if this.private.ScrollData[newid] then--如果有数据
        GuiLayoutBeginLayer(this.public.gui) --先开启这个
		GuiOptionsAddForNextWidget( this.gui, GUI_OPTION.ScrollContainer_Smooth )
        GuiBeginScrollContainer(this.public.gui, UI.NewID(id), this.private.ScrollData[newid].x,
            this.private.ScrollData[newid].y, this.private.ScrollData[newid].w, this.private.ScrollData[newid].h,
			true,this.private.ScrollData[newid].margin_x, this.private.ScrollData[newid].margin_y
        )
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
		GuiEndScrollContainer(this.public.gui)
		GuiLayoutEndLayer(this.public.gui)
	end
end

---文本输入框
---@param id string
---@param x number
---@param y number
---@param w number
---@param l number
---@param str string? str=""
---@return string
function UI.TextInput(id, x, y, w, l, str)
	str = Default(str, "")
    local newid = ConcatModID(id)
    if this.private.TextInputIDtoStr[newid] == nil then
        this.private.TextInputIDtoStr[newid] = {s_str = str,str = str}
    end
    local newStr = GuiTextInput(this.public.gui, UI.NewID(id), x, y, this.private.TextInputIDtoStr[newid].str, w, l)
	if this.private.TextInputIDtoStr[newid] ~= newStr and this.private.TextInputIDtoStr[newid].DelFr ~= 0 then--如果新文本和旧文本不匹配，那么就重新设置
        this.private.TextInputIDtoStr[newid].str = newStr
    end
    local _, _, hover = GuiGetPreviousWidgetInfo(this.public.gui)--获得当前控件是否悬浮
    if hover then
        if this.private.TextInputIDtoStr[newid].DelFr == nil then --如果在悬浮，就分配一个帧检测时间
            this.private.TextInputIDtoStr[newid].DelFr = 30
        else
            if InputIsKeyDown(Key_BACKSPACE) then --如果按了退格键
                if this.private.TextInputIDtoStr[newid].DelFr ~= 0 then
                    this.private.TextInputIDtoStr[newid].DelFr = this.private.TextInputIDtoStr[newid].DelFr - 1
                else --如果到了0
                    local input = this.private.TextInputIDtoStr[newid].str
                    this.private.TextInputIDtoStr[newid].str = Cpp.UTF8StringSub(input, 1, Cpp.UTF8StringSize(input) - 1)--删除字符
                end
            else
                this.private.TextInputIDtoStr[newid].DelFr = 30 --如果不按退格键就重置时间
            end
        end
    elseif this.private.TextInputIDtoStr[newid].DelFr then --如果未悬浮就设为空
        this.private.TextInputIDtoStr[newid].DelFr = nil
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

---恢复文本
---@param id string
function UI.TextInputRestore(id)
	local newid = ConcatModID(id)
    if this.private.TextInputIDtoStr[newid] ~= nil then
        this.private.TextInputIDtoStr[newid].str = this.private.TextInputIDtoStr[newid].s_str
    end
end

function UI.GetCheckboxEnable(id)
    local newid = ConcatModID(id)
    local CheckboxEnableKey = newid .. "_enabled"
	return ModSettingGet(CheckboxEnableKey)
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
	
	GuiZSetForNextWidget(this.public.gui, this.private.ZDeep)
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
	this.public.ScreenWidth, this.public.ScreenHeight = GuiGetScreenDimensions(this.public.gui)
	if this.private.Scale == nil then --初始化设置缩放参数
		local configXml = Nxml.parse(ReadFileAll(SavePath .. "save_shared/config.xml"))
		this.private.Scale = configXml.attr.internal_size_h / this.public.ScreenHeight
	end
	for _, fn in pairs(this.private.FirstEventFn) do
		if type(fn) == "function" then
			fn(UI)
		end
	end
	for _, fn in pairs(this.public.TickEventFn) do
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

    if this.private.destroy then
        GuiDestroy(this.private.gui)
        this.private.gui = nil
        for _, fn in pairs(this.private.DestroyCallBack) do
            if type(fn) == "function" then
                fn(UI)
            end
        end
    end
    if next(this.private.ScrollData) then --如果表有数据
        this.private.ScrollData = {}   --清空数据		
    end
	this.private.ZDeep = -114514
end

return UI

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
		FirstEventFn = {}, --用于内部优先级最高的回调函数
		NextFrNoClick = false,
		NextFrClick = 0,
        Scale = nil,  --缩放参数
		ZDeep = -114514,
		IDMax = 0x7FFFFFFF, --下一个id分配的数字
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

---组件悬浮窗提示,应当在一个组件后面使用
---@param callback function
---@param z integer
---@param xOffset integer
---@param yOffset integer
function UI.tooltips(callback, z, xOffset, yOffset)
	local gui = this.public.gui
	xOffset = Default(xOffset, 0)
	yOffset = Default(yOffset, 0)
	z = Default(z, -12)
	local left_click, right_click, hover, x, y, width, height, draw_x, draw_y, draw_width, draw_height =
		GuiGetPreviousWidgetInfo(gui)
	if draw_y > this.public.ScreenHeight * 0.5 then
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
---@param AlwaysCallBack function
---@param HoverUseCallBack function|nil
---@param ClickCallBack function
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
---@param image string
---@param scale number
---@return boolean
---@return number
---@return number
function UI.OnMoveImage(id, x, y, image, scale)
	scale = Default(scale, 1)
	local CanMoveStr = "on_move_" .. id
	ModSettingSet(CanMoveStr, true) --提前设置

	local function imageButton(gui, numId, InputX, InputY)
		GuiImage(gui, numId, InputX, InputY, image, 1, scale)
	end
	local ResultX = x
	local ResultY = y
	local function GetXY(InputResultX, InputResultY)
		ResultX = InputResultX
		ResultY = InputResultY
	end
	return UI.CanMove(id, x, y, imageButton, GetXY, nil, nil, image, true, nil, nil, scale), ResultX, ResultY
end

---自带开关显示的按钮
---@param id string
---@param x number
---@param y number
---@param Content string
---@param image string
---@param AlwaysCallBack function
---@param ClickCallBack function
---@param AlwaysCBClick boolean
---@return boolean
function UI.MoveImagePicker(id, x, y, Content, image, AlwaysCallBack, ClickCallBack, AlwaysCBClick, noMove)
	local newid = ConcatModID(id)
	if this.private.CompToPickerBool[newid] == nil then
		this.private.CompToPickerBool[newid] = false
	end
	if this.private.CompToPickerBool[newid] then
		Content = "关闭" .. Content
	else
		Content = "开启" .. Content
	end
	local TheZ = this.private.ZDeep
    local function Hover()
        UI.tooltips(function()
            GuiText(this.public.gui, 0, 0, Content)
            if not noMove then
                local shift = InputIsKeyDown(Key_LCTRL) or InputIsKeyDown(Key_RCTRL)
                if shift then
                    GuiColorSetForNextWidget(this.public.gui, 0.5, 0.5, 0.5, 1.0)
                    GuiText(this.public.gui, 0, 0, "这是可移动按钮，按shift+鼠标左键可以移动\n再点击一次鼠标左键确定位置\n鼠标右键重置位置")
                else
                    GuiColorSetForNextWidget(this.public.gui, 0.5, 0.5, 0.5, 1.0)
                    GuiText(this.public.gui, 0, 0, "按住ctrl查阅更多信息")
                end
            end
        end, TheZ, 0, 0)
    end
	this.private.ZDeep = this.private.ZDeep + 1
    local function Click(left_click, right_click, ix, iy)
        if ClickCallBack ~= nil then
            ClickCallBack(left_click, right_click, ix, iy, this.private.CompToPickerBool[newid]) --额外输入一个参数5，代表当前按钮启用状态
        end
        if left_click then
            this.private.CompToPickerBool[newid] = not this.private.CompToPickerBool[newid]
        end
    end
	GuiZSet(this.public.gui,this.private.ZDeep)
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
			if right_click and not noMove then              --如果按下右键，且是非移动的
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
				ClickCallBack(left_click, right_click,s_x,s_y)
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
		for i = max, -1 do
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
end

return UI

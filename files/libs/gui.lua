dofile_once("mods/world_editor/files/libs/fn.lua")
dofile_once("data/scripts/debug/keycodes.lua")
local Nxml = dofile_once("mods/world_editor/files/libs/nxml.lua")

local this = {
    private = {
        TileTick = {},--计划刻
        DestroyCallBack = {},--销毁时的回调函数
        destroy = false,--销毁状态
        CompToID = {},--组件转id
        NextFrNoClick = false,
        NextFrClick = 0,
        Scale = nil,
        IDMax = 0xFFFFFFFF,--下一个id分配的数字
    },
    public = {
        ScreenWidth = -1,--当前屏宽
        ScreenHeight = -1,--当前屏高
        TickEventFn = {},--刻事件
        gui = GuiCreate(),--gui userdata
    }
}

local UI = {}
setmetatable(UI, this)
this.__index = this.public

---将一个字符串拼接一下模组id的前缀然后返回
---@param str string
---@return string
local function ConcatModID(str)
    return ModID..str
end

---组件悬浮窗提示,应当在一个组件后面使用
---@param callback function
---@param z integer
---@param x_offset integer
---@param y_offset integer
function UI.tooltips(callback, z, x_offset, y_offset)
    local gui = this.public.gui
    if z == nil then z = -12; end
    local left_click,right_click,hover,x,y,width,height,draw_x,draw_y,draw_width,draw_height = GuiGetPreviousWidgetInfo( gui );
    if x_offset == nil then x_offset = 0; end
    if y_offset == nil then y_offset = 0; end
    if draw_y > this.public.ScreenHeight * 0.5 then
        y_offset = y_offset - height;
    end
    if hover then
        GuiZSet( gui, z );
        GuiLayoutBeginLayer( gui );
            GuiLayoutBeginVertical( gui, ( x + x_offset + width ), ( y + y_offset ), true );
                GuiBeginAutoBox( gui );
                    if callback ~= nil then callback(); end
                    GuiZSetForNextWidget( gui, z + 1 );
                GuiEndAutoBoxNinePiece( gui );
            GuiLayoutEnd( gui );
        GuiLayoutEndLayer( gui );
    end
end

---新建id或返回已有id
---@param str string
---@return integer
function UI.NewID(str)
    str = ConcatModID(str)--这个id很重要，最好不能重复
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

function UI.ImageButtonCanMove(id,image,s_x,s_y,moveXoffset,moveYoffset,callback)
    local true_s_x = s_x
    local true_s_y = s_y
    local newid = ConcatModID(id)
    local moveid = "move_"..id
    local imageW,imageH = GuiGetImageDimensions(this.public.gui,image)

    moveXoffset = Default(moveXoffset,imageW/2 + 1)--默认偏移参数，左上角
    moveYoffset = Default(moveYoffset,imageH/2 + 1)
    local Xname = newid.."x"
    local Yname = newid.."y"
    local CanMoveStr = "on_move_"..id

    if not ModSettingGet(CanMoveStr) then--非移动状态
        if ModSettingGet(Xname) == nil then
            ModSettingSet(Xname,s_x)
        else
            s_x = ModSettingGet(Xname)
        end
        if ModSettingGet(Yname) == nil then
            ModSettingSet(Yname,s_y)
        else
            s_y = ModSettingGet(Yname)
        end
		local hasMove = ModSettingGet(ModID.."hasButtonMove")--其他按钮移动时，移动按钮将不显示
		if not hasMove then
			local click,right = GuiImageButton(this.public.gui,UI.NewID(moveid),s_x-moveXoffset,s_y-moveYoffset,"","mods/world_editor/files/gui/images/move.png")
			if click and (not this.private.NextFrNoClick) then
				ModSettingSet(ModID.."hasButtonMove",true)
				ModSettingSet(CanMoveStr,true)
			elseif right then--如果是右键恢复默认设置
				ModSettingSet(Xname,true_s_x)
				ModSettingSet(Yname,true_s_y)
			end
		end
    
        local result = {GuiImageButton(this.public.gui,UI.NewID(id),s_x,s_y,"",image)}
        if callback ~= nil and (not hasMove) then--不执行函数操作
            callback()
        end

        return unpack(result)

    end
    --移动中
    local mx,my = InputGetMousePosOnScreen()
	mx = mx / this.private.Scale
	my = my / this.private.Scale
	if moveXoffset < 0 then
		mx = mx + moveXoffset - 1
	end
    if moveYoffset < 0 then
		my = my + moveYoffset - 1
	end

    local click = InputIsMouseButtonDown(Mouse_left)
    if click then
        ModSettingSet(CanMoveStr,false)--设置移动状态
		ModSettingSet(ModID.."hasButtonMove",false)
        ModSettingSet(Xname,mx)
        ModSettingSet(Yname,my)

        --暂停判断一段时间
        this.private.NextFrNoClick = true
        this.private.NextFrClick = 15
        this.public.TickEventFn["___NextFrNoClick"] = function ()
            if this.private.NextFrClick == 0 then
                this.private.NextFrNoClick = false
                this.public.TickEventFn["___NextFrNoClick"] = nil
            end
            this.private.NextFrClick = this.private.NextFrClick -1
        end
    end

    GuiImageButton(this.public.gui,UI.NewID(id),mx,my,"",image)
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
    this.public.ScreenWidth,this.public.ScreenHeight = GuiGetScreenDimensions( this.public.gui )
	if this.private.Scale == nil then	--初始化设置缩放参数
		local configXml = Nxml.parse(ReadFileAll(SavePath.."save_shared/config.xml"))
		this.private.Scale = configXml.attr.internal_size_h/this.public.ScreenHeight
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

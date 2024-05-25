#pragma once
#include "breakpoint.h"
#include "lua.hpp"

namespace lua {
	int MonitorNoitaLuaLoad(lua_State* L) {
		bplib::BreakPoint* Monitor = (bplib::BreakPoint*)lua_newuserdata(L, sizeof(bplib::BreakPoint));
		DWORD id = GetCurrentProcessId();
		new (Monitor) bplib::BreakPoint(id);
		long Address = luaL_checklong(L, 1);
		Monitor->SetPoint((LPVOID)Address);//0x85AF1E
		Monitor->AddPointCB((LPVOID)Address, [](PCONTEXT cont) {
			lua_State* GetLua = (lua_State*)cont->Eax;
			luaL_openlibs(GetLua);
		});
		luaL_getmetatable(L, "lua_break_point");//设置元表属性
		lua_setmetatable(L, -2);
		return 1;
	}
	int DestroyNoitaLuaLoad(lua_State* L) {//析构函数
		bplib::BreakPoint* Monitor = (bplib::BreakPoint*)lua_touserdata(L, 1);
		Monitor->~BreakPoint();//调用析构函数，防止内存泄漏
		return 0;
	}
	static luaL_Reg Monitor[] = {
		{ "__gc",DestroyNoitaLuaLoad}
	};
}

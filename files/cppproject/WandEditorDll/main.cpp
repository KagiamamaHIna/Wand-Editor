#define NOMINMAX

#include <iostream>
#include <string>
#include <filesystem>

#include "LuaFilesApi.h"
#include "LoadAllLuaLib.h"
#include "LuaRatioStr.h"
#include "lua.hpp"

//提供给lua的函数
static luaL_Reg luaLibs[] = {
	{ "CurrentPath", lua::lua_CurrentPath},
	{ "GetDirectoryPath", lua::lua_GetDirectoryPath},
	{ "GetDirectoryPathAll", lua::lua_GetDirectoryPathAll},
	{ "GetAbsPath", lua::lua_GetAbsPath},
	{ "PathGetFileName", lua::lua_PathGetFileName},
	{ "PathExists", lua::lua_PathExists},
	{ "CreateDir", lua::lua_CreateDir},

	{ "OpenMonitorLoadLuaLib",lua::MonitorNoitaLuaLoad},
	
	{ "Ratio",lua::lua_Ratio},
	{ "PartialRatio",lua::lua_PartialRatio},
	{ "PinyinRatio", lua::lua_PinyinRatio},

	{ NULL, NULL }
};

extern "C" __declspec(dllexport)
int luaopen_WandEditorDll(lua_State * L) {
	//创建元表
	luaL_newmetatable(L, "lua_break_point");
	lua_pushvalue(L, -1);//备份副本到栈顶中

	//将元表的__index字段指向自身，然后注册函数，以实现类似调用类方法的形式
	lua_setfield(L, -2, "__index");//会执行弹出操作
	luaL_register(L, NULL, lua::Monitor);

	luaL_register(L, "WandEditorDll", luaLibs);  //注册函数，参数2是模块名
	return 1;
}

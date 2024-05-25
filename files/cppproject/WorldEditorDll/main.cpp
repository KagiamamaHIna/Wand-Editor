#include <iostream>
#include <string>
#include <filesystem>

#include "LuaFilesApi.h"
#include "LoadAllLuaLib.h"
#include "lua.hpp"

//提供给lua的函数
static luaL_Reg luaLibs[] = {
	{ "CurrentPath", lua::lua_current_path},
	{ "GetDirectoryPath", lua::lua_GetDirectoryPath},
	{ "GetDirectoryPathAll", lua::lua_GetDirectoryPathAll},
	{ "GetAbsPath", lua::lua_GetAbsPath},
	{ "OpenMonitorLoadLuaLib",lua::MonitorNoitaLuaLoad},
	{ NULL, NULL }
};

extern "C" __declspec(dllexport)
int luaopen_WorldEditorDll(lua_State * L) {
	//创建元表
	
	luaL_newmetatable(L, "lua_break_point");
	lua_pushvalue(L, -1);

	//将元表的__index字段指向自身，然后注册函数，以实现类似调用类方法的形式
	lua_setfield(L, -2, "__index");//会执行弹出操作
	luaL_register(L, NULL, lua::Monitor);

	const char* const LIBRARY_NAME = "WorldEditorDll"; //模块名
	luaL_register(L, LIBRARY_NAME, luaLibs);  //注册函数
	return 1;
}

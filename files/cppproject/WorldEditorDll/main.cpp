#include <iostream>
#include <string>
#include <filesystem>

#include "LuaFilesApi.h"

#include "lua.hpp"

//提供给lua的函数
static luaL_Reg luaLibs[] = {
	{ "CurrentPath", lua::lua_current_path},
	{ "GetDirectoryPath", lua::lua_GetDirectoryPath},
	{ "GetDirectoryPathAll", lua::lua_GetDirectoryPathAll},
	{ "GetAbsPath", lua::lua_GetAbsPath},
	{ NULL, NULL }
};

extern "C" __declspec(dllexport)
int luaopen_WorldEditorDll(lua_State * L) {
	const char* const LIBRARY_NAME = "WorldEditorDll"; //模块名
	luaL_register(L, LIBRARY_NAME, luaLibs);  //注册函数
	return 1;
}

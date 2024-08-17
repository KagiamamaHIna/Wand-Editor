#define NOMINMAX

#include <iostream>
#include <string>
#include <filesystem>

#include "LuaFilesApi.h"
#include "LuaStandardLoad.h"
#include "LuaRatioStr.h"
#include "lua.hpp"

namespace lua {
	int lua_UTF8StringSub(lua_State* L) {
		pinyin::Utf8String s1 = pinyin::Utf8String(luaL_checkstring(L, 1));
		int pos1 = luaL_checkinteger(L, 2) - 1;
		int pos2 = luaL_checkinteger(L, 3) - 1;
		if (pos1 - 1 > pos2) {
			lua_pushstring(L, luaL_checkstring(L, 1));
			return 1;
		}
		std::string result = "";
		for (int i = pos1; i < pos2; i++) {
			result += s1[i];
		}
		lua_pushstring(L, result.c_str());
		return 1;
	}

	int lua_UTF8StringSize(lua_State* L) {
		pinyin::Utf8String s1 = pinyin::Utf8String(luaL_checkstring(L, 1));
		lua_pushnumber(L, s1.size());
		return 1;
	}

	int lua_SetClipboard(lua_State* L) {
		std::string str = luaL_checkstring(L, 1);
		lua_pushboolean(L, fn::SetClipboard(str));
		return 1;
	}

	int lua_GetClipboard(lua_State* L) {
		lua_pushstring(L, fn::GetClipboard().c_str());
		return 1;
	}

	int lua_SetDllDirectory(lua_State* L) {
		const char* str = luaL_checkstring(L, 1);
		lua_pushboolean(L, SetDllDirectoryA(str));
		return 1;
	}

	int lua_ConcatStr(lua_State* L) {
		int size = lua_gettop(L);
		std::string result;
		for (int i = 1; i <= size; i++) {
			result += luaL_checkstring(L, i);
		}
		lua_pushstring(L, result.c_str());
		return 1;
	}
}

//提供给lua的函数
static luaL_Reg luaLibs[] = {
	{ "CurrentPath", lua::lua_CurrentPath},
	{ "GetDirectoryPath", lua::lua_GetDirectoryPath},
	{ "GetDirectoryPathAll", lua::lua_GetDirectoryPathAll},
	{ "GetAbsPath", lua::lua_GetAbsPath},
	{ "PathGetFileName", lua::lua_PathGetFileName},
	{ "PathExists", lua::lua_PathExists},
	{ "CreateDir", lua::lua_CreateDir},
	{ "Rename", lua::lua_Rename},

	{ "UTF8StringSize", lua::lua_UTF8StringSize},
	{ "UTF8StringSub", lua::lua_UTF8StringSub},
	{ "ConcatStr", lua::lua_ConcatStr},

	{ "LoadStandardForAllLua",lua::LoadStandardForAllLua},

	{ "Ratio", lua::lua_Ratio},
	{ "PartialRatio", lua::lua_PartialRatio},
	{ "PinyinRatio", lua::lua_PinyinRatio},
	{ "AbsPartialPinyinRatio", lua::lua_AbsPartialPinyinRatio},

	{ "SetClipboard", lua::lua_SetClipboard},
	{ "GetClipboard", lua::lua_GetClipboard},
	{ "SetDllDirectory", lua::lua_SetDllDirectory},

	{ NULL, NULL }
};

extern "C" __declspec(dllexport)
int luaopen_WandEditorDll(lua_State* L) {
	luaL_register(L, "WandEditorDll", luaLibs);  //注册函数，参数2是模块名
	return 1;
}

#define NOMINMAX

#include <iostream>
#include <string>
#include <filesystem>

#include "LuaFilesApi.h"
#include "LuaStandardLoad.h"
#include "LuaRatioStr.h"
#include "lua.hpp"
#include "ImageLoad.h"
#include "LuaZip.h"
#include "LuaMemory.h"
#include "fn.h"
#include "ndata.h"

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
		for (int i = pos1; i <= pos2 && i < s1.size(); i++) {//安全检查
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

	int lua_UTF8StringChars(lua_State* L) {
		lua_newtable(L);//新建一个表
		pinyin::Utf8String s1 = pinyin::Utf8String(luaL_checkstring(L, 1));
		for (size_t i = 0; i < s1.size(); i++) {
			lua_pushstring(L, s1[i].c_str());
			lua_rawseti(L, -2, i + 1);
		}
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

	int lua_FlipImageLoadAndWrite(lua_State* L) {
		const char* FileStr = luaL_checkstring(L, 1);
		const char* WritePath = luaL_checkstring(L, 2);
		stbi_set_flip_vertically_on_load(true);
		image::stb_image img(FileStr);
		if (img.GetImageData() == nullptr) {
			luaL_error(L, "no found file");
			lua_pushboolean(L, false);
			stbi_set_flip_vertically_on_load(false);
			return 1;
		}
		auto data = img.GetImageData();
		auto height = img.GetHeight();
		auto width = img.GetWidth();
		auto channels = img.GetChannels();

		for (int y = 0; y < height; ++y) {
			for (int x = 0; x < width / 2; ++x) {
				for (int c = 0; c < channels; ++c) {
					int left = (y * width + x) * channels + c;
					int right = (y * width + (width - 1 - x)) * channels + c;
					std::swap(data[left], data[right]);
				}
			}
		}

		img.WritePng(WritePath);
		lua_pushboolean(L, true);
		stbi_set_flip_vertically_on_load(false);
		return 1;
	}

	int lua_System(lua_State* L) {
		const char* command = luaL_checkstring(L, 1);
		lua_pushnumber(L, system(command));
		return 1;
	}

	int lua_ANSIToUTF8(lua_State* L) {
		const char* str = luaL_checkstring(L, 1);
		lua_pushstring(L, fn::GbkToUtf8(str).c_str());
		return 1;
	}

	int lua_GetOriginalGunActionsLua(lua_State* L) {
		ndata::DataWak data("data/data.wak");
		lua_pushstring(L, ndata::VecU8ToStr(data["data/scripts/gun/gun_actions.lua"]).c_str());
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
	{ "CreateDirs", lua::lua_CreateDirs},
	{ "Rename", lua::lua_Rename},
	{ "Remove", lua::lua_Remove},
	{ "RemoveAll", lua::lua_RemoveAll},

	{ "NewBoolPtr", lua::lua_NewBoolPtr},
	{ "SetBoolPtrV", lua::lua_SetBoolPtrV},
	{ "GetBoolPtrV", lua::lua_GetBoolPtrV},

	{ "NewIntPtr", lua::lua_NewIntPtr},
	{ "SetIntPtrV", lua::lua_SetIntPtrV},
	{ "GetIntPtrV", lua::lua_GetIntPtrV},
	{ "Free", lua::lua_Free},

	{ "UTF8StringSize", lua::lua_UTF8StringSize},
	{ "UTF8StringSub", lua::lua_UTF8StringSub},
	{ "UTF8StringChars", lua::lua_UTF8StringChars},
	{ "ConcatStr", lua::lua_ConcatStr},

	{ "LoadStandardForAllLua",lua::LoadStandardForAllLua},

	{ "Ratio", lua::lua_Ratio},
	{ "PartialRatio", lua::lua_PartialRatio},
	{ "PinyinRatio", lua::lua_PinyinRatio},
	{ "AbsPartialPinyinRatio", lua::lua_AbsPartialPinyinRatio},

	{ "SetClipboard", lua::lua_SetClipboard},
	{ "GetClipboard", lua::lua_GetClipboard},
	{ "SetDllDirectory", lua::lua_SetDllDirectory},

	{ "FlipImageLoadAndWrite", lua::lua_FlipImageLoadAndWrite},
	{ "Uncompress", lua::lua_Uncompress},
	{ "System", lua::lua_System},

	{ "ANSIToUTF8" , lua::lua_ANSIToUTF8},

	{ "GetOriginalGunActionsLua", lua::lua_GetOriginalGunActionsLua},

	{ NULL, NULL }
};

extern "C" __declspec(dllexport)
int luaopen_WandEditorDll(lua_State* L) {
	luaL_register(L, "WandEditorDll", luaLibs);  //注册函数，参数2是模块名
	return 1;
}

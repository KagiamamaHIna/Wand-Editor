#pragma once
#include <filesystem>
#include "pinyin.h"
#include "lua.hpp"

namespace lua {
	extern pinyin::StrToPinyin pinyinData;
	int lua_Ratio(lua_State* L);
	int lua_PartialRatio(lua_State* L);
	int lua_PinyinRatio(lua_State* L);
}

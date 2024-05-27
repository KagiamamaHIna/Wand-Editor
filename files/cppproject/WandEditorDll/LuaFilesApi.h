#pragma once
#include <string>
#include <filesystem>
#include <iostream>
#include "fn.h"

#include "lua.hpp"


namespace lua {
	int lua_GetDirectoryPath(lua_State* L);
	int lua_GetDirectoryPathAll(lua_State* L);
	int lua_current_path(lua_State* L);
	int lua_GetAbsPath(lua_State* L);
	int lua_PathGetFileName(lua_State* L);
}

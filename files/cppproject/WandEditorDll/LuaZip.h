#pragma once
extern "C" {
#include "miniz.h"
}

#include <filesystem>
#include <windows.h>
#include "lua.hpp"

namespace lua {
	int lua_Uncompress(lua_State* L);
}

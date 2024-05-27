#pragma once
#include <thread>
#include <iostream>
#include <fstream>
#include "lua.hpp"

namespace lua {
	int lua_CreateThreadWrite(lua_State* L);
	int DestroyThread(lua_State* L);
	static luaL_Reg ThreadFn[] = {
		{ "__gc",DestroyThread}
	};
}

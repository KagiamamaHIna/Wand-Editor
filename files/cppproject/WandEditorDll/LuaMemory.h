#pragma once
#include "lua.hpp"

namespace lua {
	int lua_NewBoolPtr(lua_State* L);
	int lua_GetBoolPtrV(lua_State* L);
	int lua_SetBoolPtrV(lua_State* L);

	int lua_NewIntPtr(lua_State* L);
	int lua_SetIntPtrV(lua_State* L);
	int lua_GetIntPtrV(lua_State* L);

	int lua_Free(lua_State* L);
}

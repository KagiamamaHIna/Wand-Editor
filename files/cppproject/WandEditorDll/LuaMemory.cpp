#include "LuaMemory.h"

namespace lua {
	int lua_NewBoolPtr(lua_State* L) {
		bool* result = new bool;
		if (lua_gettop(L) > 0) {
			*result = lua_toboolean(L, 1);
		}
		lua_pushlightuserdata(L, result);
		return 1;
	}

	int lua_GetBoolPtrV(lua_State* L) {
		bool* ptr = (bool*)lua_touserdata(L, 1);
		lua_pushboolean(L, *ptr);
		return 1;
	}

	int lua_SetBoolPtrV(lua_State* L) {
		bool* ptr = (bool*)lua_touserdata(L, 1);
		*ptr = lua_toboolean(L, 2);
		return 0;
	}

	int lua_NewIntPtr(lua_State* L) {
		int* result = new int;
		if (lua_gettop(L) > 0) {
			*result = luaL_checkinteger(L, 1);
		}
		lua_pushlightuserdata(L, result);
		return 1;
	}

	int lua_SetIntPtrV(lua_State* L) {
		int* ptr = (int*)lua_touserdata(L, 1);
		*ptr = luaL_checkinteger(L, 2);
		return 0;
	}

	int lua_GetIntPtrV(lua_State* L) {
		int* ptr = (int*)lua_touserdata(L, 1);
		lua_pushinteger(L, *ptr);
		return 1;
	}

	int lua_Free(lua_State* L) {
		void* ptr = lua_touserdata(L, 1);
		delete ptr;
		return 0;
	}
}

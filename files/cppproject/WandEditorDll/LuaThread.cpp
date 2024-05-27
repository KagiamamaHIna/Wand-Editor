#include "LuaThread.h"

namespace lua {
	static void WriteFile(const char* path, const char* str) {
		std::fstream file;
		file.open(path, std::ios::out | std::ios::trunc);
		file << str;
		file.close();
	}
	int lua_CreateThreadWrite(lua_State* L) {
		const char* path = luaL_checkstring(L, 1);
		const char* str = luaL_checkstring(L, 2);
		std::thread* t = (std::thread*)lua_newuserdata(L, sizeof(std::thread));
		new (t) std::thread(WriteFile, path, str);//构造一下
		luaL_getmetatable(L, "lua_thread");//设置元表属性
		lua_setmetatable(L, -2);
		return 1;
	}
	int DestroyThread(lua_State* L) {//析构函数
		std::thread* t = (std::thread*)lua_touserdata(L, 1);
		t->join();//回收线程
		return 0;
	}
}

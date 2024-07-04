#include "LuaFilesApi.h"

namespace lua {
	int lua_GetDirectoryPath(lua_State* L) {//lua的C API中，实现了一个被叫做Lua虚拟栈的东西，函数传入的参数的栈索引是从1开始的
		const char* str = luaL_checkstring(L, 1);//所以1代表第一个参数
		std::filesystem::directory_iterator dir_iter(str);//这是C++标准库的东西，可以用来获得文件目录下的文件和子目录
		lua_newtable(L);//这个代表result表，先被压入栈，此时这个table的栈索引是-1
		lua_newtable(L);//这个代表path表，此时result表的栈索引被-1了，因为这个元素被压入栈了
		lua_newtable(L);//这个代表file表，和上面同理
		//经过这些操作，现在result的索引是-3(-1-1-1)，path是-2,file是-1
		int i_path = 1;
		int i_file = 1;
		for (const auto& entry : dir_iter) {
			if (entry.is_directory()) {
				lua_pushstring(L, entry.path().string().c_str());//这个函数会push元素到栈顶，会导致之前的表的索引又-1
				lua_rawseti(L, -3, i_path);//所以此时想赋值给path表，则需要再-1，所以参数是-3，这个函数会执行出栈操作，即刚刚压入的参数，并赋值在指定数组索引上
				i_path++;
			}
			else {
				lua_pushstring(L, entry.path().string().c_str());
				lua_rawseti(L, -2, i_file);//和上面的情况类似，file表原本是-1，因为lua_pushstring函数变成-2
				i_file++;
			}
		}
		//此时要进行的是将前两个path和file表写入到result表的操作
		//因为lua_rawseti会出栈，所以此时栈索引和newtable完后是一样的 
		lua_setfield(L, -3, "File");//这个函数是将当前栈顶的元素(栈索引为-1)设置到指定栈索引的表中的指定索引string中的元素
		//这个-3就是result表的栈索引，File为key，栈顶(为file表)为value
		//这个函数会执行pop操作，所以执行完成后result表的栈索引为-2
		lua_setfield(L, -2, "Path");//会执行pop操作
		//与前面类似
		return 1;//代表lua函数的返回参数，从栈索引-1为第一个返回值，刚才的lua_rawseti函数执行完后result表的栈索引为-1，所以会返回result表
	}

	int lua_GetDirectoryPathAll(lua_State* L) {//差不多是复制粘贴
		const char* str = luaL_checkstring(L, 1);//所以1代表第一个参数
		std::filesystem::recursive_directory_iterator dir_iter(str);//这是C++标准库的东西，可以用来获得文件目录下的文件和子目录
		lua_newtable(L);//这个代表result表，先被压入栈，此时这个table的栈索引是-1
		lua_newtable(L);//这个代表path表，此时result表的栈索引被-1了，因为这个元素被压入栈了
		lua_newtable(L);//这个代表file表，和上面同理
		//经过这些操作，现在result的索引是-3(-1-1-1)，path是-2,file是-1
		int i_path = 1;
		int i_file = 1;
		for (const auto& entry : dir_iter) {
			if (entry.is_directory()) {
				lua_pushstring(L, entry.path().string().c_str());//这个函数会push元素到栈顶，会导致之前的表的索引又-1
				lua_rawseti(L, -3, i_path);//所以此时想赋值给path表，则需要再-1，所以参数是-3，这个函数会执行出栈操作，即刚刚压入的参数，并赋值在指定数组索引上
				i_path++;
			}
			else {
				lua_pushstring(L, entry.path().string().c_str());
				lua_rawseti(L, -2, i_file);//和上面的情况类似，file表原本是-1，因为lua_pushstring函数变成-2
				i_file++;
			}
		}
		//此时要进行的是将前两个path和file表写入到result表的操作
		//因为lua_rawseti会出栈，索引此时栈索引和newtable完后是一样的 
		lua_setfield(L, -3, "File");//这个函数是将当前栈顶的元素(栈索引为-1)设置到指定栈索引的表中的指定索引string中的元素
		//这个-3就是result表的栈索引，File为key，栈顶(为file表)为value
		//这个函数会执行pop操作，所以执行完成后result表的栈索引为-2
		lua_setfield(L, -2, "Path");//会执行pop操作
		//与前面类似
		return 1;//代表lua函数的返回参数，从栈索引-1为第一个返回值，刚才的lua_rawseti函数执行完后result表的栈索引为-1，所以会返回result表
	}

	int lua_CurrentPath(lua_State* L) {
		lua_pushstring(L, std::filesystem::current_path().string().c_str());
		return 1;
	}

	int lua_PathExists(lua_State* L) {
		std::string str = luaL_checkstring(L, 1);
		lua_pushboolean(L, std::filesystem::exists(str));
		return 1;
	}

	int lua_CreateDir(lua_State* L) {
		std::string str = luaL_checkstring(L, 1);
		lua_pushboolean(L, std::filesystem::create_directory(str));
		return 1;
	}

	int lua_PathGetFileName(lua_State* L) {
		std::string str = luaL_checkstring(L, 1);
		size_t pos = str.rfind('/');
		size_t pos2 = str.rfind('\\');
		if (pos == -1 && pos2 == -1) {
			std::cerr << "not found file name\n";
			return 0;
		}
		if (pos2 > pos) {
			pos = pos2;
		}
		//有结果
		str = str.substr(pos + 1);
		lua_pushstring(L, str.c_str());
		return 1;
	}

	int lua_GetAbsPath(lua_State* L) {
		if (lua_isstring(L, 1)) {
			std::string arg = luaL_checkstring(L, 1);
			lua_pushstring(L, fn::GetAbsPath(arg).c_str());
			return 1;
		}
		return 0;
	}

	int lua_Rename(lua_State* L) {
		const char* path = luaL_checkstring(L, 1);
		const char* tar = luaL_checkstring(L, 2);
		lua_pushinteger(L, std::rename(path, tar));
		return 1;
	}
}

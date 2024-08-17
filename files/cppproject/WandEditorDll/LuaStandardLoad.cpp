#include "LuaStandardLoad.h"

namespace lua {
	static bplib::BreakPoint* lookNewstate = nullptr;

	void CheckLuaNewstate(PCONTEXT cont) {
		size_t stackPtr = cont->Esp;
		uint32_t ptr = *(uint32_t*)stackPtr;

		if (!lookNewstate->HasPoint((LPVOID)ptr)) {
			lookNewstate->SetPoint((LPVOID)ptr);
			lookNewstate->AddPointCB((LPVOID)ptr, [](PCONTEXT cont) {
				lua_State* L = (lua_State*)cont->Eax;
				luaL_openlibs(L);
			});
		}
	}

	int LoadStandardForAllLua(lua_State* L) {
		if (lookNewstate == nullptr) {
			lookNewstate = new bplib::BreakPoint(GetCurrentProcessId());
			lookNewstate->SetPoint((LPVOID)luaL_newstate);
			lookNewstate->AddPointCB((LPVOID)luaL_newstate, CheckLuaNewstate);
		}
		return 0;
	}
}

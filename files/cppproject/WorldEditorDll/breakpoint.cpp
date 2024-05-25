#include "breakpoint.h"

namespace bplib {
	std::unordered_map<BreakPoint*, bool> BreakPoint::AllBreakPoint = std::unordered_map<BreakPoint*, bool>();
	bool BreakPoint::InitExceptionFilter = false;
	void BreakPoint::SetPoint(LPVOID Address) {//设置断点
		DWORD oldProtect;
		BYTE Command;
		VirtualProtectEx(process, Address, 1, PAGE_EXECUTE_READWRITE, &oldProtect);
		ReadProcessMemory(process, Address, &Command, 1, NULL); // 保存原始字节
		WriteProcessMemory(process, Address, "\xCC", 1, NULL); // \xCC 是 INT 3 指令，用于产生软件断点
		VirtualProtectEx(process, Address, 1, oldProtect, &oldProtect);
		if (!OriginalCommand.count(Address)) {//如果没保存过
			OriginalCommand[Address] = Command;//存储地址
			ReadProcessMemory(process, Address, &Command, 1, NULL);
		}
	}

	bool BreakPoint::AddPointCB(LPVOID Address, BreakPointCallBack CB) {
		if (OriginalCommand.count(Address)) {//如果为空则返回假，因为要判断是否设置了断点
			if (AddressCB.count(Address)) {//这里是判断向量是否创建
				//创建了
				AddressCB[Address].push_back(CB);
			}
			else {//没创建
				AddressCB[Address] = std::vector<BreakPointCallBack>(1);
				AddressCB[Address][0] = CB;
			}
			return true;
		}
		return false;
	}

	bool BreakPoint::RemovePoint(LPVOID Address) {
		if (OriginalCommand.count(Address)) {//确定有指令
			RestoreCommand(Address);//恢复指令
			//移除数据
			OriginalCommand.erase(Address);
			AddressCB.erase(Address);
			return true;
		}
		return false;
	}

	void BreakPoint::RestoreCommand(LPVOID Address) {//恢复指令
		DWORD oldProtect;
		BYTE* Command = &OriginalCommand[Address];
		VirtualProtectEx(process, Address, 1, PAGE_EXECUTE_READWRITE, &oldProtect);
		WriteProcessMemory(process, Address, Command, 1, NULL); // 恢复原始字节
		VirtualProtectEx(process, Address, 1, oldProtect, &oldProtect);
	}
}

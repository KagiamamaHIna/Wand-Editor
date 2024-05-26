#pragma once
#include <windows.h>
#include <thread>
#include <iostream>
#include <vector>
#include <mutex>
#include <unordered_map>

namespace bplib {
	typedef void(*BreakPointCallBack) (PCONTEXT);
	class BreakPoint {
	public:
		BreakPoint(DWORD pid) :TargetProgram{pid} {
			if (!InitExceptionFilter) {
				SetUnhandledExceptionFilter(ExceptionFilter);
				InitExceptionFilter = true;
			}
			process = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pid);
			AllBreakPoint[this] = true;
		}
		~BreakPoint() {
			for (auto& v : OriginalCommand) {//恢复指令
				RestoreCommand(v.first);
			}
			AllBreakPoint.erase(this);//删除自身
		}
		void SetPoint(LPVOID Address);//设置断点
		bool AddPointCB(LPVOID Address, BreakPointCallBack);//返回代表这次添加回调是否成功
		bool RemovePoint(LPVOID Address);

	private:
		DWORD TargetProgram = 0;//目标程序的pid
		std::unordered_map<LPVOID, BYTE> OriginalCommand;
		std::unordered_map<LPVOID, std::vector<BreakPointCallBack>> AddressCB;
		HANDLE process;//进程句柄
		LPVOID UpAddress = 0;//上一次执行的地址

		void RestoreCommand(LPVOID Address);//恢复指令
		static std::unordered_map<BreakPoint*, bool> AllBreakPoint;
		static bool InitExceptionFilter;

		static LONG WINAPI ExceptionFilter(EXCEPTION_POINTERS* pExceptionInfo) {
			//检查是否为INT3断点异常
			if (pExceptionInfo->ExceptionRecord->ExceptionCode == EXCEPTION_BREAKPOINT) {
				PVOID address = pExceptionInfo->ExceptionRecord->ExceptionAddress;
				
				for (auto& v : AllBreakPoint) {
					if (v.first->OriginalCommand.count(address)) {
						v.first->RestoreCommand(address);//恢复指令
						for (auto& v : v.first->AddressCB[address]) {//调用回调函数
							v(pExceptionInfo->ContextRecord);
						}
						v.first->UpAddress = address;
						//设置单步执行
						pExceptionInfo->ContextRecord->EFlags |= 0x100;
					}
				}
				return EXCEPTION_CONTINUE_EXECUTION; //继续执行程序
			}
			//检查是否为单步执行异常
			else if (pExceptionInfo->ExceptionRecord->ExceptionCode == EXCEPTION_SINGLE_STEP) {
				for (auto& v : AllBreakPoint) {
					if (v.first->UpAddress) {//如果存有则代表有
						v.first->SetPoint(v.first->UpAddress);//重新设置0xCC异常
						v.first->UpAddress = 0;
					}
				}
				return EXCEPTION_CONTINUE_EXECUTION;
			}
			return EXCEPTION_CONTINUE_SEARCH; //其他异常继续搜索处理程序
		}
	};
}

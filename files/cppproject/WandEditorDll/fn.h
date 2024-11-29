#pragma once
#include <string>
#include <windows.h>
#include <iostream>

namespace fn {
	std::string GetAbsPath(std::string& Path);
	bool SetClipboard(const std::string& str);
	std::string GetClipboard();
	std::string GbkToUtf8(const char* gbk);
	std::string GetRegistryValue(HKEY rootKey, const std::string& subKey, const std::string& valueName);
}

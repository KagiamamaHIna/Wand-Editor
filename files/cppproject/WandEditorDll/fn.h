#pragma once
#include <string>
#include <windows.h>

namespace fn {
	std::string GetAbsPath(std::string& Path);
	bool SetClipboard(const std::string& str);
	std::string GetClipboard();
}

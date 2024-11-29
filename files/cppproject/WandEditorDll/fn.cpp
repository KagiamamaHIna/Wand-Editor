#include "fn.h"

namespace fn {
	std::string GetAbsPath(std::string& Path) {//把字符串中的系统变量转换成对应的字符串
		std::string sysBuf = "";
		std::string ReturnStr = "";
		size_t i = 0;
		while (Path[i]) {//分割参数
			if (Path[i] != '%') {
				ReturnStr += Path[i];
			}
			else if (Path[i] == '%') {
				i++;
				bool pass = true;
				while (Path[i] != '%') {
					sysBuf += Path[i];
					i++;
					if (i > Path.length() - 1) {
						pass = false;
						i--;//防止越界
						break;
					}
				}
				if (pass) {
					sysBuf = getenv(sysBuf.c_str());
				}
				ReturnStr += sysBuf;
				sysBuf = "";
			}
			i++;
		}
		return ReturnStr;
	}

	std::string Utf8ToGbk(const char* utf8) {
		int len = MultiByteToWideChar(CP_UTF8, 0, utf8, -1, NULL, 0);
		wchar_t* wszGBK = new wchar_t[len + 1];
		memset(wszGBK, 0, len * 2 + 2);
		MultiByteToWideChar(CP_UTF8, 0, utf8, -1, wszGBK, len);
		len = WideCharToMultiByte(CP_ACP, 0, wszGBK, -1, NULL, 0, NULL, NULL);
		char* szGBK = new char[len + 1];
		memset(szGBK, 0, len + 1);
		WideCharToMultiByte(CP_ACP, 0, wszGBK, -1, szGBK, len, NULL, NULL);
		std::string strTemp(szGBK);
		if (wszGBK) delete[] wszGBK;
		if (szGBK) delete[] szGBK;
		return strTemp;
	}

	std::string GbkToUtf8(const char* gbk) {
		int len = MultiByteToWideChar(CP_ACP, 0, gbk, -1, NULL, 0);
		wchar_t* wszGBK = new wchar_t[len + 1];
		memset(wszGBK, 0, len * 2 + 2);
		MultiByteToWideChar(CP_ACP, 0, gbk, -1, wszGBK, len);
		len = WideCharToMultiByte(CP_UTF8, 0, wszGBK, -1, NULL, 0, NULL, NULL);
		char* szGBK = new char[len + 1];
		memset(szGBK, 0, len + 1);
		WideCharToMultiByte(CP_UTF8, 0, wszGBK, -1, szGBK, len, NULL, NULL);
		std::string strTemp(szGBK);
		if (wszGBK) delete[] wszGBK;
		if (szGBK) delete[] szGBK;
		return strTemp;
	}

	std::string Utf8ToGbk(const std::string& str) {
		return Utf8ToGbk(str.c_str());
	}

	bool SetClipboard(const std::string& str) {//干脆不写编码转换算了（
		if (!OpenClipboard(nullptr)) {
			return false;
		}
		//清空剪贴板
		EmptyClipboard();

		//分配全局内存，用于剪贴板数据
		HGLOBAL hClipboardData = GlobalAlloc(GMEM_DDESHARE, str.length() + 1);
		if (hClipboardData == nullptr) {
			return false;
		}
		//锁定内存，准备设置数据
		char* pchData = (char*)GlobalLock(hClipboardData);
		if (pchData == nullptr) {
			return false;
		}
		strcpy(pchData, str.c_str());
		//解锁内存
		GlobalUnlock(hClipboardData);
		//设置剪贴板数据
		SetClipboardData(CF_TEXT, hClipboardData);
		//关闭剪贴板
		CloseClipboard();
		return true;
	}

	std::string GetClipboard() {
		if (!OpenClipboard(nullptr)) {
			return "";
		}
		std::string result = "";
		//检查剪贴板中是否有文本格式的数据
		if (IsClipboardFormatAvailable(CF_TEXT)) {
			//获取剪贴板数据
			HANDLE hData = GetClipboardData(CF_TEXT);
			if (hData != nullptr) {
				//锁定内存，读取数据
				char* pText = (char*)GlobalLock(hData);
				if (pText != nullptr) {
					//设置剪贴板文本
					result = pText;
					//解锁内存
					GlobalUnlock(hData);
				}
			}
		}
		//关闭剪贴板
		CloseClipboard();
		return result;
	}

	std::string GetRegistryValue(HKEY rootKey, const std::string& subKey, const std::string& valueName) {
		HKEY hKey;
		DWORD valueLength = 0;
		DWORD valueType;

		//打开注册表键
		if (RegOpenKeyExA(rootKey, subKey.c_str(), 0, KEY_READ, &hKey) == ERROR_SUCCESS) {
			//第一次调用 获取值的长度
			if (RegQueryValueExA(hKey, valueName.c_str(), nullptr, &valueType, nullptr, &valueLength) == ERROR_SUCCESS) {
				//分配缓冲区
				std::string result(valueLength - 1, '\0');
				//第二次调用 实际获取值
				if (RegQueryValueExA(hKey, valueName.c_str(), nullptr, &valueType, LPBYTE(result.data()), &valueLength) == ERROR_SUCCESS) {
					//关闭注册表键
					RegCloseKey(hKey);
					return result;
				}
				else {
					std::cerr << "WandEditor:Failed to query value: " << valueName << std::endl;
				}
			}
			else {
				std::cerr << "WandEditor:Failed to retrieve the length of value: " << valueName << std::endl;
			}
			//关闭注册表键
			RegCloseKey(hKey);
		}
		else {
			std::cerr << "WandEditor:Failed to open registry key: " << subKey << std::endl;
		}

		return "";
	}
}

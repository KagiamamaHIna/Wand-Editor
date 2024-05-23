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
}

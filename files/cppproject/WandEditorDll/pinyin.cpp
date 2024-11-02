#include "pinyin.h"

namespace pinyin {
	//函数定义
	//Unicode码转utf8字节流
	std::string UnicodeToUtf8(char32_t unicodeChar) {
		std::string utf8;
		if (unicodeChar <= 0x7F) {
			//1字节数据
			utf8 += static_cast<char>(unicodeChar);
		}
		else if (unicodeChar <= 0x7FF) {
			//2字节数据
			utf8 += static_cast<char>(0xC0 | ((unicodeChar >> 6) & 0x1F));
			utf8 += static_cast<char>(0x80 | (unicodeChar & 0x3F));
		}
		else if (unicodeChar <= 0xFFFF) {
			//3字节数据
			utf8 += static_cast<char>(0xE0 | ((unicodeChar >> 12) & 0x0F));
			utf8 += static_cast<char>(0x80 | ((unicodeChar >> 6) & 0x3F));
			utf8 += static_cast<char>(0x80 | (unicodeChar & 0x3F));
		}
		else if (unicodeChar <= 0x10FFFF) {
			//4字节数据
			utf8 += static_cast<char>(0xF0 | ((unicodeChar >> 18) & 0x07));
			utf8 += static_cast<char>(0x80 | ((unicodeChar >> 12) & 0x3F));
			utf8 += static_cast<char>(0x80 | ((unicodeChar >> 6) & 0x3F));
			utf8 += static_cast<char>(0x80 | (unicodeChar & 0x3F));
		}
		return utf8;
	}

	int HexStrToInt(const std::string& str) {
		int result;
		sscanf_s(str.c_str(), "%X", &result);
		return result;
	}

	std::vector<std::string> split(const std::string& str, char delimiter) {
		std::vector<std::string> result;
		size_t start = 0;
		size_t end = str.find(delimiter);

		while (end != std::string::npos) {
			result.push_back(str.substr(start, end - start));
			start = end + 1;
			end = str.find(delimiter, start);
		}

		result.push_back(str.substr(start));
		return result;
	}

	//用于处理utf8字符串
	Utf8String::Utf8String(const std::string& input) {
		uint8_t bitmask;//掩码
		size_t i = 0;
		size_t ByteSizeCount;
		while (input[i]) {//遍历字符串
			bitmask = 1;
			ByteSizeCount = 0;
			bitmask &= (input[i] >> (sizeof(char) * 8 - 1));
			if (bitmask == 1) {//如果是1，代表需要计数得知字符大小
				while (bitmask) {//计算字符长度
					ByteSizeCount++;//自增一下
					bitmask = 1;
					bitmask &= (input[i] >> ((sizeof(char) * 8 - 1) - ByteSizeCount));//char大小不定，为了兼容性这样写
				}
				if (i + ByteSizeCount > input.size()) {
					ByteSizeCount = input.size() - i;
				}
				str.push_back(input.substr(i, ByteSizeCount));//截取字符串
				i += ByteSizeCount - 1;//对字符串索引进行一下更改
			}
			else {//代表是0，则只有一个字节大小
				str.push_back(input.substr(i, 1));
			}
			i++;
		}
	}

	//StrToPinyin类
	//初始化数据
	std::unordered_map<std::string, std::string> StrToPinyin::toneMap = std::unordered_map<std::string, std::string>({
		{"ā", "a"}, {"á", "a"}, {"ǎ", "a"}, {"à", "a"},
		{"ē", "e"}, {"é", "e"}, {"ě", "e"}, {"è", "e"},
		{"ī", "i"}, {"í", "i"}, {"ǐ", "i"}, {"ì", "i"},
		{"ō", "o"}, {"ó", "o"}, {"ǒ", "o"}, {"ò", "o"},
		{"ū", "u"}, {"ú", "u"}, {"ǔ", "u"}, {"ù", "u"},
		{"ü", "v"}, {"ǘ", "v"}, {"ǚ", "v"}, {"ǜ", "v"},
		{"ń", "n"}, {"ň", "n"}, {"ǹ", "n"},
		{"ḿ", "m"}
	});

	StrToPinyin::StrToPinyin(const std::string& path) {
		std::fstream fs = std::fstream(path, std::ios::in);
		if (!fs.is_open()) {//未成功打开 
			std::cerr << "file did not open successfully(StrToPinyin)\n";
			throw PinyinFileNoGet();
		}
		//开始读取
		std::string str;
		while (std::getline(fs, str)) {
			Utf8String utf8str = Utf8String(str);//将字节流转换为utf8表示的字符串
			size_t i = 0;
			while (!utf8str[i].empty() && utf8str[i] != "#") {//#为注释
				if (utf8str[i] == "U" && i < utf8str.size() - 1) {//判断是否合法
					if (utf8str[i + 1] == "+") {
						std::string key;
						i = i + 2;//往后移两位，准备开始存储数字
						while (!utf8str[i].empty() && utf8str[i] != ":") {//第一个是判空，第二个是判终点
							key += utf8str[i];
							i++;
						}
						i++;//不要:符号
						std::string pinyinbuf;
						//现在应该开始构造拼音表
						while (!utf8str[i].empty() && utf8str[i] != "#") {
							if (utf8str[i] != " ") {
								pinyinbuf += utf8str[i];
							}
							i++;
						}
						key = UnicodeToUtf8(HexStrToInt(key));
						data[key] = split(pinyinbuf, ',');//设置
						break;//退出这次循环，读取下一行
					}
				}
				i++;
			}
		}
	}
	bool StrToPinyin::HasPinyin(const std::string& str)const {
		return static_cast<bool>(data.count(str));
	}

	std::vector<std::string> StrToPinyin::GetPinyin(const std::string& str, bool hasTone)const {
		if (!data.count(str)) {//没数据返回由输入字符串组成的向量
			return std::vector<std::string>{str};
		}
		if (hasTone) {//如果需要音调就直接返回
			return data.at(str);
		}
		//不需要音调需要处理
		std::vector<std::string> pinyinData = data.at(str);
		std::vector<std::string> result;
		std::unordered_map<std::string, bool> hasStr;
		for (auto& v : pinyinData) {
			Utf8String utf8v = Utf8String(v);
			for (size_t i = 0; i < utf8v.size(); i++) {
				if (toneMap.count(utf8v[i])) {
					utf8v[i] = toneMap.at(utf8v[i]);
				}
			}
			std::string value = utf8v.ToStream();
			if (not hasStr[value]) {
				hasStr[value] = true;
				result.push_back(value);
			}
		}
		return result;
	}
}

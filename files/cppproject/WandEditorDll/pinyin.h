#pragma once
#include <fstream>
#include <iostream>
#include <string>
#include <exception>
#include <unordered_map>
#include <rapidfuzz/fuzz.hpp>

namespace pinyin {
	//Unicode码转utf8字节流
	std::string UnicodeToUtf8(char32_t);
	//十六进制数字字符串转int
	int HexStrToInt(const std::string&);

	std::vector<std::string> split(const std::string& str, char delimiter);

	class Utf8String {
	public:
		Utf8String(const std::string& input);

		std::string ToStream()const {
			std::string result;
			for (const auto& v : str) {
				result += v;
			}
			return result;
		}

		std::string& operator[](size_t i) {
			return str[i];
		}

		const std::string& operator[](size_t i)const {
			return str[i];
		}

		std::string& at(size_t i) {
			return str.at(i);
		}

		const std::string& at(size_t i)const {
			return str.at(i);
		}

		size_t size()const {
			return str.size();
		}
	private:
		std::vector<std::string> str;
	};

	class PinyinFileNoGet : public std::exception {
	public:
		virtual const char* what() {
			return "File not successfully opened";
		}
	};

	class StrToPinyin {
	public:
		StrToPinyin(const std::string& path);
		std::vector<std::string> GetPinyin(const std::string& str,bool hasTone = false)const;
		bool HasPinyin(const std::string& str)const;
	private:
		static std::unordered_map<std::string, std::string> toneMap;//有声调拼音转无声调拼音关联表
		std::unordered_map<std::string, std::vector<std::string>> data;
	};
}

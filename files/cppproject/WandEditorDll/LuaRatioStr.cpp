#include "LuaRatioStr.h"

namespace lua {
	//初始化
	pinyin::StrToPinyin pinyinData = pinyin::StrToPinyin(std::filesystem::current_path().string() + "/mods/wand_editor/files/pinyin/pinyin.txt");

	int lua_Ratio(lua_State* L) {
		const char* s1 = luaL_checkstring(L, 1);
		const char* s2 = luaL_checkstring(L, 2);
		lua_pushnumber(L, rapidfuzz::fuzz::ratio(s1, s2));
		return 1;
	}

	int lua_PartialRatio(lua_State* L) {
		const char* s1 = luaL_checkstring(L, 1);
		const char* s2 = luaL_checkstring(L, 2);
		lua_pushnumber(L, rapidfuzz::fuzz::partial_ratio(s1, s2));
		return 1;
	}

	int lua_PinyinRatio(lua_State* L) {
		std::string s1 = luaL_checkstring(L, 1);
		std::string s2 = luaL_checkstring(L, 2);
		double score = rapidfuzz::fuzz::ratio(s1, s2);//进行初步匹配
		std::string temp;
		pinyin::Utf8String utf8s1 = pinyin::Utf8String(s1);
		std::vector<double> AllScore;
		for (size_t i = 0; i < utf8s1.size(); i++) {
			if (pinyinData.HasPinyin(utf8s1[i])) {
				if (!temp.empty()) {//如果有数据
					AllScore.push_back(rapidfuzz::fuzz::partial_ratio(temp, s2));//计算相似程度
					temp.clear();//清除
				}
				std::vector<std::string> pinyin = pinyinData.GetPinyin(utf8s1[i]);
				double tempScore = 0;
				for (const auto& v : pinyin) {//遍历判断哪个匹配程度最高
					double temp = rapidfuzz::fuzz::partial_ratio(v, s2);
					if (temp > tempScore) {
						tempScore = temp;
					}
				}
				AllScore.push_back(tempScore);
			}
			else {//如果不是带有拼音的字符就把他们拼接起来处理
				temp += utf8s1[i];
			}
		}
		double FinalScore = 0;
		for (const auto& v : AllScore) {//计算总值
			FinalScore += v;
		}
		if (AllScore.size()) {
			FinalScore /= AllScore.size();//计算平均数，还有不能除以0
		}
		if (FinalScore > score && AllScore.size()) {//顺带判断容器空不空
			lua_pushnumber(L, FinalScore);
		}
		else {
			lua_pushnumber(L, score);
		}
		return 1;
	}
}

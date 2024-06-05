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
		std::vector<std::vector<std::string>> pinyinBuf;
		pinyin::Utf8String utf8s1 = pinyin::Utf8String(s1);
		for (size_t i = 0; i < utf8s1.size(); i++) {//收集数据 
			if (pinyinData.HasPinyin(utf8s1[i])) {
				if (!temp.empty()) {//如果不为空,那就保存为一个单一的向量
					pinyinBuf.push_back(std::vector<std::string>{temp});
					temp.clear();
				}
				pinyinBuf.push_back(pinyinData.GetPinyin(utf8s1[i]));
			}
			else {//如果不是带有拼音的字符就把他们拼接起来处理
				temp += utf8s1[i];
			}
		}
		std::stack<std::pair<int, std::string>> stk;//用栈模拟递归函数行为
		stk.push({ 0, "" }); //初始索引为0，初始字符串为空

		while (!stk.empty()) {
			auto [index, current] = stk.top();//结构化绑定赋值
			stk.pop();
			//如果索引等于data的大小，表示一个组合已经完成
			if (index == pinyinBuf.size()) {
				double NewScore = rapidfuzz::fuzz::ratio(current, s2);
				if (NewScore > score) {
					score = NewScore;
				}
				continue;
			}
			//将下一个索引的所有字符串加入栈中
			for (const auto& str : pinyinBuf[index]) {
				stk.push({ index + 1, current + str });
			}
		}
		lua_pushnumber(L, score);
		return 1;
	}
}

# Wand Editor
这是一个Noita模组，由C++和Lua编写，为Noita提供强大的法杖编辑的功能等。

## 目前主要支持以下内容：

1.一个模仿原版风格的法杖编辑栏

2.支持导出导入，翻页，预览属性，正确的预览法术，正确的保存法杖的法杖仓库

3.中英支持（英文可能不准确，为了方便使用了机翻）

4.一个能自定义更多功能的法杖生成器

5.拼音/原文搜索法术，收藏法术

6.使用id搜索法术

7.模糊搜索策略搜索法术，打错了也可以搜到

8.分离的无敌/变形免疫

8.锁定你的血量，防止你的血量被更改

9.真正的禁止施法

10.刷新手持魔杖的法术使用次数

11.禁用法术投射物粒子

12.无后坐力

13.像spell lab那样的伤害信息显示

14.支持科学计数法的假人伤害显示

15.清除你发射的投射物

16.清除手持魔杖的延迟

## 如何编译cppproject里的项目
请下载vs2022并用vs2022打开这个项目，

下载[rapidfuzz-cpp-3.0.4](https://github.com/rapidfuzz/rapidfuzz-cpp/releases/tag/v3.0.4)和克隆lua5.1/luajit的仓库，将这两个仓库的文件夹放在项目同级文件夹中，

lua的文件夹请命名为"lua"，或者在项目中手动更改路径

根据编译脚本编译完成lua后即可在vs2022中编译此项目

# 致谢
goki_dev所开发的Goki' Things和Spell lab，法杖编辑器参考了其中的部分代码或者是直接使用了部分代码，有一部分贴图也是来源于此

wand dbg的开发者：wand dbg的一些设计是法杖编辑器的灵感来源

nxml库：简直就是必备品（）

[pinyin-data](https://github.com/mozillazg/pinyin-data)项目：法杖编辑器使用了此项目的数据用于实现拼音搜索

[rapidfuzz-cpp](https://github.com/rapidfuzz/rapidfuzz-cpp)项目：法杖编辑器使用这个库实现了模糊搜索功能

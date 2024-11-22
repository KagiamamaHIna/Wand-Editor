ModDir = "mods/wand_editor/"
ModID = "wand_editor"
ModVersion = "1.8.4"
ModLink = "https://github.com/KagiamamaHIna/Wand-Editor"

QuietNaN = 0/0

DebugMode = false

--NoAutoUpdate = false 大概是废案了吧

NoRewriteList = {
    "mods/wand_editor/cache", --先不要删掉缓存，后续再删
    "mods/wand_editor/.git",
    "mods/wand_editor/.editorconfig",
    "mods/wand_editor/.gitignore",
    "mods/wand_editor/files/cppproject",
    "mods/wand_editor/files/module/debug",
	"mods/wand_editor/files/biome_impl/wand_lab/reset"
}

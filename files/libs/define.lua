dofile_once("data/scripts/gun/gun_enums.lua")
ModDir = "mods/wand_editor/"
ModID = "wand_editor"
ModVersion = "1.1.2"
ModLink = "https://github.com/KagiamamaHIna/Wand-Editor"

SpellTypeBG = {
	[ACTION_TYPE_PROJECTILE] = "data/ui_gfx/inventory/item_bg_projectile.png",
	[ACTION_TYPE_STATIC_PROJECTILE] = "data/ui_gfx/inventory/item_bg_static_projectile.png",
	[ACTION_TYPE_MODIFIER] = "data/ui_gfx/inventory/item_bg_modifier.png",
	[ACTION_TYPE_DRAW_MANY] = "data/ui_gfx/inventory/item_bg_draw_many.png",
	[ACTION_TYPE_MATERIAL] = "data/ui_gfx/inventory/item_bg_material.png",
	[ACTION_TYPE_OTHER] = "data/ui_gfx/inventory/item_bg_other.png",
	[ACTION_TYPE_UTILITY] = "data/ui_gfx/inventory/item_bg_utility.png",
	[ACTION_TYPE_PASSIVE] = "data/ui_gfx/inventory/item_bg_passive.png"
}

QuietNaN = 0/0

DebugMode = false

--[[
    DefaultTowerRarities (ModuleScript)
    Path: ServerStorage → Configs
    Parent: Configs
    Exported: 2026-09-29 15:57:28
]]
local DEFAULT_TOWER_RARITIES = {
	
	["Common"] = {
		Rarity = 1/50, 
		isCommon = true
	},
	
	["Uncommon"] = {
		Rarity = 1/500
	},
	
	
	["Rare"] = {
		Rarity = 1/1500
	},
	
	["Epic"] = { 
		Rarity = 1/2250
	},
	
	
	["Legendary"] = {
		Rarity = 1/5000
	}
	
	
}

return DEFAULT_TOWER_RARITIES

--[[
    Buffs (ModuleScript)
    Path: ServerStorage → Configs
    Parent: Configs
    Exported: 2026-09-29 15:57:28
]]
	local Buffs = {
	
	--TOWER BUFFS
	
	TowerUpgrade = {
		Name = "Tower Upgrade",

		AllowedEntities = {
			Tower = true,
			Enemy = false,
		},

		Modifiers = {
			Damage = {
				Type = "Multiplier",
				Value = 0.6,
			},
		},

		MaxStacks = 30,
		Duration = -1,
	},
	
	
	--ENEMY DEBUFFS / BUFFS

	Slow = {
		Name = "Slow",

		AllowedEntities = {
			Tower = false,
			Enemy = true,
		},

		Modifiers = {
			Speed = {
				Type = "Multiplier",
				Value = -0.20,
			},
		},

		MaxStacks = 1,
		Duration = 5,
	},

	
	
	
}





return Buffs

--[[
    Enemies (ModuleScript)
    Path: ServerStorage → Configs
    Parent: Configs
    Exported: 2026-09-29 15:57:28
]]
local Enemies = {
	
	["Slime"] = {
		["Name"] = "Slime",
		["Health"] = 30,
		["Reward"] = 300, 
		["Speed"] = 5,
		["Damage"] = 10,
		
		["Type"] = "Ground", --reserved
		["Level"] = 1,
	},
	
	["EmuOtori"] = {
		["Name"] = "EmuOtori",
		["Health"] = 500,
		["Reward"] = 100, 
		["Speed"] = 5,
		["Damage"] = 10,

		["Type"] = "Ground", --reserved
		["Level"] = 1,
	},
	
	["Slime King"] = {
		["Name"] = "Slime King",
		["Health"] = 750,
		["Reward"] = 200, 
		["Speed"] = 3,
		["Damage"] = 50,

		["Type"] = "Ground", --reserved
		["Level"] = 1,
		
		--Skills
		Skills = {
			["Slime Summon"] = {
				Cooldown = 2.5,
				Type = "Summon",
				Enemy = "Slime Summon",
				
				SummonType = "SummonBurst",
				SummonAmount = {3, 5}
			},
			
			["Slime Heal"] = {
				Cooldown = 10,
				
				SkillFunction = function(enemyData)
					local remainingHP = enemyData.Stats.MaxHP - enemyData.Stats.Hp
					local hpPercentage = remainingHP / enemyData.Stats.MaxHP
					
					if hpPercentage <= 0.5 then
						enemyData.hp = math.min(enemyData.Stats.Hp * 1.1, enemyData.Stats.MaxHP)
						print("Healed 10%")
					end
				end,
			}
		}
	},
	
	
	["Slime Summon"] = {
		["Name"] = "Slime Summon",
		["Health"] = 50,
		["Reward"] = 1, 
		["Speed"] = 9,
		["Damage"] = 50,

		["Type"] = "Ground", --reserved
		["Level"] = 1,
	},
}

return Enemies

--[[
    Towers (ModuleScript)
    Path: ServerStorage → Configs
    Parent: Configs
    Exported: 2026-09-29 15:57:28
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Debris = game:GetService("Debris")


local EnemyManager = require(ServerStorage:WaitForChild("Modules"):WaitForChild("EnemyManager"))

local AssetsFolder = ReplicatedStorage:WaitForChild("Assets")

local ModelsFolder = AssetsFolder:WaitForChild("Models")

local TOWERS = {
	["Common"] = {

		{
			Name = "Slinger",
			Rarity = "Common",
			Stats = {
				Firerate = 0.8,
				Damage = 8, -- ~10 DPS (Standard starter mid-range)
				Range = 25,
			
			},
		},
		
		{
			Name = "Fire Wizard",
			Rarity = "Common",
			Targeting = "Custom",
			Stats = {
				Firerate = 1.5,
				Damage = 30, -- ~10 DPS (Standard starter mid-range)
				Range = 25,

			},
			
			Attack = function(target)
				local rangeIndicator = workspace:WaitForChild("FirePart"):Clone()
				
				if not target then return false end
				
				local pos = target.Position
				local direction = target.Direction

				rangeIndicator.CFrame = CFrame.lookAt(pos, pos + direction)
				rangeIndicator.Parent = workspace
				
				
				Debris:AddItem(rangeIndicator, 1.5)
				local targets = EnemyManager:GetEnemiesInArea(rangeIndicator)
				print(targets)
				
			end,
		},

		
		--{
		--	Name = "Lightning Wizard",
		--	Rarity = "Legendary",
		--	Stats = {
		--		Firerate = 2.5,
		--		Damage = 300, -- ~10 DPS (Standard starter mid-range)
		--		Range = 30,

		--	},

		--	Targeting = "Chain"
		--}
		
		
	},

	["Uncommon"] = {
		{
			Name = "Archer",
			Rarity = "Uncommon",
			Stats = {
				Firerate = 1.0,
				Damage = 25, -- ~25 DPS (Long range sniper)
				Range = 35
			},
		},
	},

	["Rare"] = {
		{
			Name = "Crossbow",
			Rarity = "Rare",
			Stats = {
				Firerate = 0.5,
				Damage = 40, -- ~80 DPS (High single-target burst)
				Range = 40
			},
		},
	},

	["Epic"] = {
		{
			Name = "Gunner",
			Rarity = "Epic",
			Stats = {
				Firerate = 0.1,
				Damage = 25, -- ~250 DPS (Rapid fire)
				Range = 45,
				
				CritChance = 0.05,
				CritDamage = 1.5, --50%
			},
		},
	},

	["Legendary"] = {
		{
			Name = "Machine Gunner",
			Rarity = "Legendary",
			Stats = {
				Firerate = 0.05, -- 20 shots/sec (Safe engine limit)
				Damage = 80, -- ~1,000 DPS (Late-game powerhouse)
				Range = 50,
				
				CritChance = 0.05,
				CritDamage = 1.5, --50%
			},
		},
		
		
		{
			Name = "Lightning Wizard",
			Rarity = "Legendary",
			Stats = {
				Firerate = 1.5,
				Damage = 300, -- ~10 DPS (Standard starter mid-range)
				Range = 30,

			},

			Targeting = "Chain"
		}
	},
}

return TOWERS


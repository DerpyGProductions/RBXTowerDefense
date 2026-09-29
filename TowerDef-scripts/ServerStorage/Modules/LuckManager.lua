--[[
    LuckManager (ModuleScript)
    Path: ServerStorage → Modules
    Parent: Modules
    Exported: 2026-09-29 15:57:27
]]
local ServerStorage = game:GetService("ServerStorage")
local DefaultConfigs = ServerStorage:WaitForChild("Configs")


local DEFAULT_TOWER_RARITIES = require(DefaultConfigs:WaitForChild("DefaultTowerRarities"))

local LuckManager = {}

function LuckManager:GetRandom(items, luckMultiplier)
	luckMultiplier = luckMultiplier or 1 -- 1 = standard luck

	local effectiveWeights = {}
	local totalWeight = 0

	-- Boost non-common rarity weights by luck
	for i, rarity in ipairs(items) do
		local weight = rarity.isCommon and rarity.rarity or (rarity.rarity * luckMultiplier)
		effectiveWeights[i] = weight
		totalWeight = totalWeight + weight
	end

	local randomValue = math.random() * totalWeight
	local cumulativeWeight = 0

	for i, rarity in ipairs(items) do
		cumulativeWeight = cumulativeWeight + effectiveWeights[i]
		if randomValue <= cumulativeWeight then
			return rarity.name
		end
	end
end

function LuckManager:GetWeightedProbabilities(items, luckMultiplier)
	luckMultiplier = luckMultiplier or 1
	local totalWeight = 0
	local effectiveWeights = {}

	--computing updated weights and sum
	for rarity, data in ipairs(items) do
		local weight = data.isCommon and data.rarity or (data.rarity * luckMultiplier)
		effectiveWeights[rarity] = weight
		totalWeight = totalWeight + weight
	end

	--calculate true probability for each rarity
	local probabilities = {}
	for rarity, data in ipairs(items) do
		local trueProb = effectiveWeights[rarity] / totalWeight
		probabilities[rarity] = {
			chance = trueProb,
			percentage = string.format("%.4f%%", trueProb * 100),
			oneIn = string.format("1 in %.1f", 1 / trueProb)
		}
	end

	return probabilities
end

function LuckManager:GetNextSummonRarity(luckMultiplier)
	luckMultiplier = luckMultiplier or 1 -- 1 = standard luck

	local effectiveWeights = {}
	local totalWeight = 0

	-- Boost non-common rarity weights by luck
	for rarity, data in pairs(DEFAULT_TOWER_RARITIES) do
		local weight = data.isCommon and data.Rarity or (data.Rarity * luckMultiplier)
		effectiveWeights[rarity] = weight
		totalWeight = totalWeight + weight
	end

	local randomValue = math.random() * totalWeight
	local cumulativeWeight = 0

	for rarity, data in pairs(DEFAULT_TOWER_RARITIES) do
		cumulativeWeight = cumulativeWeight + effectiveWeights[rarity]
		if randomValue <= cumulativeWeight then
			return rarity --returns the rarity
		end
	end
	
end



return LuckManager

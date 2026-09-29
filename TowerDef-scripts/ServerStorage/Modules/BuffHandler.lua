--[[
    BuffHandler (ModuleScript)
    Path: ServerStorage → Modules
    Parent: Modules
    Exported: 2026-09-29 15:57:27
]]
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = ReplicatedStorage:WaitForChild("Remotes")

local Events = ServerStorage:WaitForChild("Events")
local Configs = ServerStorage:WaitForChild("Configs")

local AddBuffEvent = Events:WaitForChild("AddBuff")
local Buffs = require(Configs:WaitForChild("Buffs"))

local TowerHandler = require(script.Parent:WaitForChild("TowerHandler"))
local EnemyManager = require(script.Parent:WaitForChild("EnemyManager"))

local UpdateEnemyEvent = RemoteEvents:WaitForChild("UpdateEnemies")

local BuffHandler = {}
BuffHandler.ActiveBuffs = {}

local function generateBuffID()
	local id
	repeat
		id = "Buff_" .. math.random(1000, 9999)
	until not BuffHandler.ActiveBuffs[id]
	return id
end

-- Retrieves all physical entity tables affected by a given buff target scope
function BuffHandler:GetAffectedEntities(buffInstance)
	local affectedTowers = {}
	local affectedEnemies = {}
	
	
	local targetType = buffInstance.TargetType
	local target = buffInstance.Target
	local targetRarity = buffInstance.TargetRarity

	if targetType == "Tower" or targetType == "Entity" then
		local tower = TowerHandler:GetTower(target)
		if tower then table.insert(affectedTowers, tower) end
		
	elseif targetType == "TargetRarityPlayer" then
		local towers = TowerHandler:GetPlayerTowersOnRarity(target, targetRarity)
		
		if not towers then return end
		for _, tower in pairs(towers) do
			table.insert(affectedTowers, tower)
		end

	elseif targetType == "Enemy" then
		local enemy = EnemyManager:GetEnemy(target)
		
		--print(`Enemy {enemy} , {target}`)
		if enemy then table.insert(affectedEnemies, enemy) end

	elseif targetType == "Player" then
		for _, tower in pairs(TowerHandler.ActivePlayerTowers[target]) do
			table.insert(affectedTowers, tower)
		end

	elseif targetType == "Global" then
		for _, tower in pairs(TowerHandler.ActiveTowers) do
			table.insert(affectedTowers, tower)
		end
	end

	return affectedTowers, affectedEnemies
end

function BuffHandler:AddBuff(buffData, targetInfo, stacks)
	stacks = stacks or 1
	local buffConfig = type(buffData) == "string" and Buffs[buffData] or buffData
	if not buffConfig then warn("Buff configuration not found") return end

	local buffType = buffConfig.Name
	local targetType = targetInfo.TargetType or "Tower"
	local targetId = targetInfo.Target

	-- Refresh or stack existing active buff on the same target
	for _, existingBuff in pairs(BuffHandler.ActiveBuffs) do
		if existingBuff.Type == buffType and existingBuff.Target == targetId and existingBuff.TargetType == targetType then
			existingBuff.Stacks = math.min(existingBuff.Stacks + stacks, buffConfig.MaxStacks or 1)
			if buffConfig.Duration > 0 then
				existingBuff.ExpiresAt = os.clock() + buffConfig.Duration
			end
			BuffHandler:RecalculateBuffs()
			return existingBuff
		end
	end

	local id = generateBuffID()
	local buffInstance = {
		ID = id,
		Type = buffType,
		Config = buffConfig,
		
		TargetType = targetType,
		Target = targetId,
		
		TargetRarity = targetInfo.TargetRarity,
		
		SourceType = targetInfo.SourceType,
		Source = targetInfo.Source,
		Stacks = math.min(stacks, buffConfig.MaxStacks or 1),
		Duration = buffConfig.Duration,
		ExpiresAt = buffConfig.Duration > 0 and (os.clock() + buffConfig.Duration) or -1,
	}

	BuffHandler.ActiveBuffs[id] = buffInstance
	BuffHandler:RecalculateBuffs()

	return buffInstance
end

function BuffHandler:RemoveBuff(buffID)
	if not BuffHandler.ActiveBuffs[buffID] then return end
	BuffHandler.ActiveBuffs[buffID] = nil
	BuffHandler:RecalculateBuffs()
end

function BuffHandler:RecalculateBuffs()
	local currentTime = os.clock()
	local expiredBuffs = {}

	-- Accumulator maps for stacked modifiers per entity
	local towerMods = {} -- [towerID] = { Multipliers = {}, Flats = {} }
	local enemyMods = {} -- [enemyID] = { Multipliers = {}, Flats = {} }

	-- 1. Gather all active buff modifiers
	for buffID, buff in pairs(BuffHandler.ActiveBuffs) do
		if buff.ExpiresAt > 0 and currentTime >= buff.ExpiresAt then
			table.insert(expiredBuffs, buffID)
			continue
		end

		local affectedTowers, affectedEnemies = BuffHandler:GetAffectedEntities(buff)
		local config = buff.Config
		
		if not affectedTowers then continue end
		if not affectedEnemies then continue end

		-- Accumulate tower modifiers
		for _, tower in ipairs(affectedTowers) do
			if not towerMods[tower.ID] then
				towerMods[tower.ID] = { Multipliers = {}, Flats = {} }
			end

			for statName, mod in pairs(config.Modifiers) do
				if mod.Type == "Multiplier" then
					towerMods[tower.ID].Multipliers[statName] = (towerMods[tower.ID].Multipliers[statName] or 0) + (mod.Value * buff.Stacks)
				elseif mod.Type == "Flat" then
					towerMods[tower.ID].Flats[statName] = (towerMods[tower.ID].Flats[statName] or 0) + (mod.Value * buff.Stacks)
				end
			end
		end

		-- Accumulate enemy modifiers
		for _, enemy in ipairs(affectedEnemies) do
			if not enemyMods[enemy.enemyId] then
				enemyMods[enemy.enemyId] = { Multipliers = {}, Flats = {} }
			end

			for statName, mod in pairs(config.Modifiers) do
				if mod.Type == "Multiplier" then
					enemyMods[enemy.enemyId].Multipliers[statName] = (enemyMods[enemy.enemyId].Multipliers[statName] or 0) + (mod.Value * buff.Stacks)
				elseif mod.Type == "Flat" then
					enemyMods[enemy.enemyId].Flats[statName] = (enemyMods[enemy.enemyId].Flats[statName] or 0) + (mod.Value * buff.Stacks)
				end
			end
		end
	end

	-- Clean up expired buffs
	for _, buffID in ipairs(expiredBuffs) do
		BuffHandler.ActiveBuffs[buffID] = nil
	end

	-- 2. Dynamically calculate and set tower.Stats using tower.BaseStats
	for towerID, tower in pairs(TowerHandler.ActiveTowers) do
		if not tower.BaseStats then continue end

		local mods = towerMods[towerID] or { Multipliers = {}, Flats = {} }

		-- Dynamically iterate over all stat keys in BaseStats (Damage, Firerate, Range, etc.)
		for statName, baseValue in pairs(tower.BaseStats) do
			local mult = mods.Multipliers[statName] or 0
			local flat = mods.Flats[statName] or 0

			if statName == "Firerate" then
				-- Higher firerate buff multiplier reduces attack delay time safely
				tower.Stats.Firerate = math.max(0.01, baseValue / math.max(0.1, 1 + mult))
			else
				-- General formula: Base * (1 + MultiplierSum) + FlatSum
				tower.Stats[statName] = math.max(0, (baseValue * (1 + mult)) + flat)
				
			end
		end
	end

	-- 3. Apply speed/stat modifiers to active enemies
	for enemyID, enemy in pairs(EnemyManager.ActiveEnemies) do
		local mods = enemyMods[enemyID] or { Multipliers = {}, Flats = {} }

		local mult = mods.Multipliers.Speed or 0
		local flat = mods.Flats.Speed or 0
		
		local oldSpeed = enemy.Stats["Speed"]
	
		enemy.Stats.Speed = math.max(0, (enemy.BaseStats.Speed * (1 + mult)) + flat)
		
		if oldSpeed ~= enemy.Stats["Speed"] then
			--print("Applied buff to enemy:", enemyID, mods, " Result:", enemy.Stats["Speed"])
			
			local enemyData = table.clone(enemy.Stats)
			enemyData.isSlowed = true
			
			--UpdateEnemyEvent:FireAllClients(enemyID, enemyData)
		end
		
	end
end

function BuffHandler:Start()
	AddBuffEvent.OnInvoke = function(buff, target, stacks)
		return BuffHandler:AddBuff(buff, target, stacks)
	end
	
	Events.RecalculateBuffs.Event:Connect(function()
		BuffHandler:RecalculateBuffs()
	end)

	-- Heartbeat loop checks timed buff expirations smoothly
	RunService.Heartbeat:Connect(function()
		local currentTime = os.clock()
		local needsRecalculation = false

		for buffID, buff in pairs(BuffHandler.ActiveBuffs) do
			if buff.ExpiresAt > 0 and currentTime >= buff.ExpiresAt then
				needsRecalculation = true
				break
			end
		end

		if needsRecalculation then
			BuffHandler:RecalculateBuffs()
		end
	end)
end

return BuffHandler
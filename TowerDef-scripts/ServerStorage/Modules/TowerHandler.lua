--[[
    TowerHandler (ModuleScript)
    Path: ServerStorage → Modules
    Parent: Modules
    Exported: 2026-09-29 15:57:27
]]
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Configs = ServerStorage:WaitForChild("Configs")
local Events = ServerStorage:WaitForChild("Events")

local TileManager = require(script.Parent:WaitForChild("TileManager"))
local EnemyManager = require(script.Parent:WaitForChild("EnemyManager"))
local StateManager = require(script.Parent:WaitForChild("StateManager"))

local Towers = require(Configs:WaitForChild("Towers"))
local Buffs = require(Configs:WaitForChild("Buffs"))

local Owl = require(ReplicatedStorage.OwlKnit.Owl)
local TowerHandler

const MAX_EFFECTS_PER_BATCH = 120
const EFFECT_FLUSH_INTERVAL = 1/12

local function client()
	return Owl.GetService("GameService").Client
end

local function queueAttackEffect(towerID, targetID, attackType, chainTargets)
	local queue = TowerHandler.PendingAttackEffects
	if #queue >= MAX_EFFECTS_PER_BATCH then return end
	queue[#queue + 1] = { towerID, targetID, attackType, chainTargets}
end

local function flushAttackEffects(now)
	if #TowerHandler.PendingAttackEffects == 0 or now - TowerHandler.LastEffectFlush < EFFECT_FLUSH_INTERVAL then return end
	client().TowerAttack:FireAll(TowerHandler.PendingAttackEffects)
	TowerHandler.PendingAttackEffects = {}
	TowerHandler.LastEffectFlush = now
end

TowerHandler = {}

TowerHandler.CurrentBuffID = 0

TowerHandler.ActiveTowers = {}
TowerHandler.ActivePlayerTowers = {}

TowerHandler.ActivePlayerBuffs = {}
TowerHandler.ActiveGlobalBuffs = {}

-- Cosmetics are lossy: cap and batch attack effects to protect each client's budget.
TowerHandler.PendingAttackEffects = {}
TowerHandler.LastEffectFlush = 0
local EFFECT_FLUSH_INTERVAL = 1 / 12
local MAX_EFFECTS_PER_BATCH = 24

local RarityColors = {
	Common = Color3.new(1,1,1), 
	Uncommon = Color3.new(0, 1, 0.2),
	Rare = Color3.new(0.184314, 0.713725, 1),
	Epic = Color3.new(0.85098, 0, 1),
	Legendary = Color3.new(1, 0.619608, 0.0823529)
}


local function generateID() --generates unique id for tower
	while true do
		local currentID = "Tower_" .. math.random(1000, 10000)
		if not TowerHandler.ActiveTowers[currentID] then
			return currentID
		end
		task.wait()
	end
end

local function checkRarity(tower, allowedRarity)
	
	for _, rarity in pairs(allowedRarity) do
		if tower.Rarity == rarity then return true end
	end
	return false
end

function TowerHandler:GetPlayerTowersOnRarity(player, allowedRarity)
	
	local playerTowers = TowerHandler.ActivePlayerTowers[player]
	
	if not playerTowers then warn("Player towers does not exist") return end
	
	local towers = {}
	
	for towerID, tower in pairs(playerTowers) do
		local isAllowed = checkRarity(tower, allowedRarity)
		if isAllowed then
			towers[towerID] = tower
		end
	end
	
	return towers
	
end

function TowerHandler:InitTowerFolders()
	
	for i, player in pairs(Players:GetPlayers()) do
		local playerID = StateManager:GetPlayerID(player.UserId)
		
		if not playerID then warn(`{player.Name} does not have player ID set up`) continue end
		
		local towerFolder = Instance.new("Folder")
		towerFolder.Name = `Player{playerID}`
		
		towerFolder.Parent = workspace.Towers
	end
	
end


local function createRangeIndicator(size, parent)
	
	local size = size or 1.5
	local Range = Instance.new("Part")
	Range.Name = "RarityIndicator"
	Range.Size = Vector3.new(size,0.1,size)
	Range.Anchored = true
	Range.Shape = "Ball"
	Range.Transparency = 0.2
	Range.Material = Enum.Material.SmoothPlastic
	Range.Parent = parent
	
	Range.CanCollide = false
	
	
	return Range
end

function TowerHandler:PlaceTower(player, currentSummon, towerID, tile)
	local summonModel = ReplicatedStorage.Assets.Models.Towers[currentSummon.Rarity]:FindFirstChild(currentSummon.Name)
	if not summonModel then
		summonModel = workspace.Slime
	end
	
	local playerID = StateManager:GetPlayerID(player.UserId)
	
	print(`Player ID: {playerID}`)

	local availableTiles = TileManager:GetUnplacedTiles(player)
	
	--print(#availableTiles)
	if #availableTiles == 0 then warn("No available tiles") return end
	--print(tile)
	local tile = tile or availableTiles[math.random(1, #availableTiles)]

	--summon the model
	summonModel = summonModel:Clone()
	summonModel.Name = towerID
	local size = summonModel:GetExtentsSize().Y * 0.5
	
	summonModel:SetAttribute("TowerID", towerID)
	summonModel:SetAttribute("Rarity", currentSummon.Rarity)
	summonModel:SetAttribute("TowerName", currentSummon.Name)
	
	local towerStats = currentSummon.Stats

	if summonModel:FindFirstChild("Humanoid") then
		local humanoid = summonModel.Humanoid
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

		-- Force the humanoid into a low-cost state
		humanoid:ChangeState(Enum.HumanoidStateType.None)
	end

	local folder = workspace.Towers:FindFirstChild(`Player{playerID}`)
	
	if not folder then warn("Player folder does not exist") return end
	summonModel.Parent = folder
	
	
	summonModel:PivotTo(tile.CFrame * CFrame.new(0, size, 0))
	

	local rangeSize = Vector3.new(towerStats.Range * 2 ,0.15,towerStats.Range * 2)
	
	local rangeIndicator = Instance.new("Part")
	rangeIndicator.Shape = "Ball"
	rangeIndicator.Name = "Range"
	rangeIndicator.Size = rangeSize
	rangeIndicator.Anchored = true
	rangeIndicator.BrickColor = BrickColor.new("White")
	rangeIndicator.Position = tile.Position + Vector3.new(0, 0.2, 0)
	rangeIndicator.Transparency = 1
	rangeIndicator.Parent = summonModel
	rangeIndicator.Material = Enum.Material.SmoothPlastic
	rangeIndicator.CastShadow = false
	rangeIndicator.CanCollide = false
	rangeIndicator.CanTouch = false
	--rangeIndicator.CanQuery = false
	
	
	local rarityIndicator = createRangeIndicator()
	rarityIndicator.Color = RarityColors[currentSummon.Rarity]
	rarityIndicator.Position = tile.Position + Vector3.new(0, 0.5, 0)
	
	tile:SetAttribute("OccupiedTower", towerID)
	rangeIndicator:SetAttribute("Size", rangeSize)

	TileManager:SetPlacedTile(player, tile)
	
	return summonModel, rangeIndicator, tile, size
end


function TowerHandler:SwapTowers(player, sourceTower, targetTile)
	if not sourceTower or not targetTile then return false end
	
	
	local PlayerID = StateManager:GetPlayerID(player.UserId)
	local sourceTowerModel = sourceTower.Model
	local sourceTile = sourceTower.Tile
	local targetTowerID = targetTile:GetAttribute("OccupiedTower")
	
	if sourceTowerModel:GetAttribute("Moving") then warn("Tower is already moving") return end
	
	if not targetTile:HasTag(`Player{PlayerID}Tile`) then warn("Player does not own target tile") return end

	if not targetTowerID then
		-- Scenario A: Relocate to an empty tile
		sourceTile:SetAttribute("OccupiedTower", nil)
		targetTile:SetAttribute("OccupiedTower", sourceTower.ID)

		if TileManager.SwapTile then
			TileManager:SwapTile(player, sourceTile, targetTile)
		end

		sourceTower.Tile = targetTile
		sourceTower.Moving = true
		sourceTower.MoveStart = sourceTowerModel:GetPivot()
		sourceTower.MoveElapsed = 0
		sourceTower.MoveDestination = targetTile.CFrame * CFrame.new(0, sourceTower.Size, 0)
		
		sourceTower.Model:SetAttribute("Moving", true)
	else
		-- Scenario B: Swap positions between two towers
		local targetTower = TowerHandler:GetTower(targetTowerID)
		if not targetTower then return false end

		local targetTowerModel = targetTower.Model
		
		if targetTowerModel:GetAttribute("Moving") then warn("Tower is already moving") return end

		-- Swap Occupied Attributes on Tiles
		sourceTile:SetAttribute("OccupiedTower", targetTower.ID)
		targetTile:SetAttribute("OccupiedTower", sourceTower.ID)

		-- Swap Tile references in Tower Data
		sourceTower.Tile = targetTile
		targetTower.Tile = sourceTile

		-- Animate Source Tower to Target Tile
		sourceTower.Moving = true
		sourceTower.MoveStart = sourceTowerModel:GetPivot()
		sourceTower.MoveElapsed = 0
		sourceTower.MoveDestination = targetTile.CFrame * CFrame.new(0, sourceTower.Size, 0)

		-- Animate Target Tower to Source Tile
		targetTower.Moving = true
		targetTower.MoveStart = targetTowerModel:GetPivot() -- Fixed: Now gets target tower's actual pivot
		targetTower.MoveElapsed = 0
		targetTower.MoveDestination = sourceTile.CFrame * CFrame.new(0, targetTower.Size, 0)
		
		sourceTower.Model:SetAttribute("Moving", true)
		targetTower.Model:SetAttribute("Moving", true)
	end

	return true
end


function TowerHandler:InitTower(player, currentSummon, chosenTile)
	
	local towerID = generateID()
	
	local model, rangeIndicator, tile, size = TowerHandler:PlaceTower(player, currentSummon, towerID, chosenTile)
	
	if model == nil then return false end
	
	local towerData = {
		ID = towerID,
		
		Name = currentSummon.Name,
		Rarity = currentSummon.Rarity,
		Model = model,
		RangeIndicator = rangeIndicator,
		
		AttackType = currentSummon.Targeting,
		
		Owner = player.UserId,
		OwnerObject = player,
	
		BaseStats = table.clone(currentSummon.Stats),
		Stats = table.clone(currentSummon.Stats), --the one that will be modified
		
		LastTarget = nil,
		
		LastAttack = 0,
		Tile = tile,
		Size = size,
		
		Attack = currentSummon.Attack,
		
		Buffs = {}
	}
	
	
	TowerHandler.ActiveTowers[towerID] = towerData
	
	if not TowerHandler.ActivePlayerTowers[player.UserId] then
		TowerHandler.ActivePlayerTowers[player.UserId] = {}
	end
	TowerHandler.ActivePlayerTowers[player.UserId][towerID] = towerData
	
	Events.RecalculateBuffs:Fire()
	return true
	
	--print(towerID, TowerHandler.ActiveTowers)
	
end

local params = OverlapParams.new()
params.FilterType = Enum.RaycastFilterType.Include



--Target Helpers

local function getTargetSpatial(tower)
	local boxCFrame = tower.RangeIndicator.CFrame
	local boxSize = tower.RangeIndicator.Size + Vector3.new(0, 5, 0)

	local hitboxes, activeEnemies = EnemyManager:GetEnemyHitboxes()
	params.FilterDescendantsInstances = {hitboxes} --only include enemy hitboxes

	local parts = workspace:GetPartBoundsInBox(boxCFrame, boxSize, params)

	--print(hitboxes)
	local bestEnemy = nil
	local bestWaypoint = -1
	local bestAlpha = -1
	
	for i, part in pairs(parts) do
		local enemyId = part:GetAttribute("EnemyID")
		local data = EnemyManager:GetEnemy(enemyId)
		
		if not data then continue end
		if data.Stats.Hp <= 0 then continue end
		
		if data.Waypoint > bestWaypoint then
			bestWaypoint = data.Waypoint
			bestAlpha = data.Alpha
			bestEnemy = enemyId
		elseif data.Waypoint == bestWaypoint and data.Alpha > bestAlpha then
			bestEnemy = enemyId
			bestAlpha = data.Alpha
		end	
	end
	
	--print(bestEnemy)
	return bestEnemy
	
end

local function checkInRange(pos1, pos2, range)
	
	--print(pos1, pos2, debug.traceback("Called from: "))
	local diff = pos1 - pos2
	local distanceSquared = ((diff.X * diff.X) + (diff.Y * diff.Y) + (diff.Z * diff.Z))
	
	return distanceSquared < (range * range)
end

local function getTarget(tower)
	local towerPos = tower.Model:GetPivot().Position

	if tower.LastTarget then
		local lastId = tower.LastTarget.enemyId
		local activeEnemy = EnemyManager.ActiveEnemies[lastId]
		local lastPos = tower.LastTarget.Position

		if activeEnemy and tower.LastTarget.Stats.Hp > 0 and lastPos then
			if checkInRange(towerPos, lastPos, tower.Stats.Range) then
				return tower.LastTarget
			end
		end
	end

	local bestEnemy = nil
	local maxDistance = -1

	for enemyId, enemy in pairs(EnemyManager.ActiveEnemies) do
		if not enemy or enemy.Stats.Hp <= 0 then continue end

		-- Safely get position fallback if Position hasn't updated yzet
		local enemyPos = enemy.Position
		if not enemyPos then continue end

		local inRange = checkInRange(towerPos, enemyPos, tower.Stats.Range)
		if not inRange then continue end
		
		local distance = enemy.TotalDistance or 0
		
		if distance > maxDistance then
			maxDistance = distance
			bestEnemy = enemy
		end

		--if enemy.Waypoint > bestWaypoint then
		--	bestWaypoint = enemy.Waypoint
		--	bestAlpha = enemy.Alpha
		--	bestEnemy = enemy
		--elseif enemy.Waypoint == bestWaypoint and enemy.Alpha > bestAlpha then
		--	bestEnemy = enemy
		--	bestAlpha = enemy.Alpha
		--end	
	end

	tower.LastTarget = bestEnemy
	return bestEnemy

end




local function getChainTargets(tower, maxChains)
	local primaryEnemy = getTarget(tower)

	if not primaryEnemy then return {}, nil end
	
	local chainTargets = {}
	local currentIndex = 1
	
	local id = tonumber(string.split(primaryEnemy.enemyId, "Enemy_")[2])
	local maxLookup = 50
	
	--print(id)
	while #chainTargets < maxChains do
		
		
		local nextEnemy = EnemyManager:GetEnemy("Enemy_" .. id + currentIndex)
		local previousEnemy = EnemyManager:GetEnemy("Enemy_" .. id - currentIndex)
		
		if nextEnemy ~= nil and nextEnemy.Stats.Hp > 0 then
			table.insert(chainTargets, nextEnemy)
		end
			
		if previousEnemy ~= nil and previousEnemy.Stats.Hp > 0 then
			table.insert(chainTargets, previousEnemy)
		end
		
		if currentIndex >= maxLookup then break end
		
		currentIndex += 1
		
	end
	return chainTargets, primaryEnemy
	
end

function TowerHandler:RemoveTower(towerID, merged)
	local tower = TowerHandler:GetTower(towerID)
	if not tower then return end
	
	--print(towerID, tower)
	
	if not merged then
		TileManager:SetUnplacedTile(tower.Owner, tower.Tile)
	end
	
	tower.Model:Destroy()
	
	tower.Tile:SetAttribute("OccupiedTower", nil)
	
	
	TowerHandler.ActivePlayerTowers[tower.Owner][towerID] = nil
	TowerHandler.ActiveTowers[towerID] = nil
	
	--print(tower)
end


function TowerHandler:GetTower(towerID)
	return TowerHandler.ActiveTowers[towerID]
end

function TowerHandler:StopTowers()
	if not TowerHandler.Heartbeat then return end
	TowerHandler.Heartbeat:Disconnect()
	TowerHandler.Heartbeat = nil
end


local function damageEnemy(target, tower, damage)
	target.Stats.Hp -= damage or tower.Stats.Damage
	
	if target.Model then
		target.Model:SetAttribute("Health", target.Stats.Hp)
	end
	
	local reward = target.Stats.Reward
	local hp = target.Stats.Hp
	local target = { 
		enemyId = target.enemyId,
	}

	
	if hp <= 0 then --remove the enemy if dead
		StateManager:IncrementAll("Money", reward) --gives money

		for i, player in pairs(Players:GetPlayers()) do
			client().MoneyChanged:Fire(player, StateManager:GetState(player.UserId, "Money"))
		end
		EnemyManager:RemoveEnemy(target.enemyId)
	end
	
	return target
end


function TowerHandler:HandleTowerAttack(towerData)
	
	if towerData.AttackType == nil or towerData.AttackType == "Single" then --Single Attacking
		
		--print("single")
		local target = getTarget(towerData)
		if not target then return false end

		--print(target)
		
		local target = damageEnemy(target, towerData)
		queueAttackEffect(tonumber(string.split(towerData.ID, "Tower_")[2]), tonumber(string.split(target.enemyId, "Enemy_")[2]), "Projectile")
		
	
	elseif towerData.AttackType == "Chain" then
		local targets, mainTarget = getChainTargets(towerData, 7)
		if not targets or #targets == 0 then return false end
		
		
		--print(targets, mainTarget)
		local baseDamage = towerData.Stats.Damage
		
		local main_target = { --reduce the data needed to be sent in the client
			enemyId = mainTarget.enemyId,
			hp = mainTarget.Stats.Hp,
			maxHP = mainTarget.Stats.MaxHP,
			reward = mainTarget.Stats.Reward
		}
		
		local chained_targets = {}

		for i, target in pairs(targets) do
			--print(target)
			
			local chainedDamage = baseDamage * (1 - (i * 0.1))
			table.insert(chained_targets, damageEnemy(target, nil, chainedDamage))
			
			local targetData = {
				TargetType = "Enemy",
				Target = target.enemyId
			}
			
			
			if target then
				EnemyManager:UpdateEnemyState(target, math.min(target.Stats.Speed * 0.7, 4))
			end
			
			--Events.AddBuff:Invoke("Slow", targetData, 1)
		end
		
		
		local compactTargets = table.create(#chained_targets)
		
		
		for index, hit in ipairs(chained_targets) do
			compactTargets[index] = tonumber(string.split(hit.enemyId, "Enemy_")[2])
		end
		print(chained_targets, compactTargets)
		queueAttackEffect(tonumber(string.split(towerData.ID, "Tower_")[2]), tonumber(string.split(main_target.enemyId, "Enemy_")[2]), "Chain", compactTargets)	
		
	elseif towerData.AttackType == "AOE" then
		local target = getTarget(towerData)
		if not target then return false end

		towerData.Attack(target)

		queueAttackEffect(tonumber(string.split(towerData.ID, "Tower_")[2]), tonumber(string.split(target.enemyId, "Enemy_")[2]), "Projectile")

		
	elseif towerData.AttackType == "Custom" then

	end
	
	
	return true
end

function TowerHandler:UpdateTowers(delta)

	--if #TowerHandler.ActiveTowers == 0 then return end
	local currentTime = os.clock()

	for towerID, tower in pairs(TowerHandler.ActiveTowers) do
		--sprint(towerID, tower)
		
		if tower.Moving then
			tower.MoveElapsed += delta
			tower.Alpha = math.clamp(tower.MoveElapsed / 1.5, 0, 1)
			
			tower.Model:PivotTo(tower.MoveStart:Lerp(tower.MoveDestination, tower.Alpha))

			-- Disconnect the loop once the lerp is finished
			if tower.Alpha >= 1 then
				tower.Moving = false
				tower.Model:SetAttribute("Moving", false)
			end
		
	
		elseif currentTime - tower.LastAttack >= tower.Stats.Firerate then
			
			tower.LastAttack = currentTime
			
			local success = TowerHandler:HandleTowerAttack(tower)
			
			if not success then tower.LastAttack = 0 continue end
			
			
			--local target = getTarget(tower, activeEnemies)

			--if target then
			--	tower.LastAttack = currentTime
			--	-- 2. Notify Clients to render visuals
			--	TowerAttackedRemote:FireAllClients(tower.Model, target.Model, tower.Config.AttackType)
			--end
			
			
		end
	end

	flushAttackEffects(currentTime)

end



--Tower Buffs Handler

function TowerHandler:AddBuff(towerID, buffName)
	
	if not Buffs[buffName] then warn(`Buff {buffName} does not exist`) return end
	
	local buffData = Buffs[buffName]
	local tower = TowerHandler:GetTower(towerID)
	local originalTowerData = Towers[tower.Name]
	local buffID = TowerHandler.CurrentBuffID
	
	TowerHandler.CurrentBuffID += 1
	
	
	tower.Buffs[buffID] = {
		Name = buffName,
		Stats = buffData.Stats,
		Type = buffData.Type
	}
	
	
	TowerHandler:RecalculateBuffs(towerID)
	--Apply the buff to the tower
	
end

function TowerHandler:RecalculateBuffs(towerID)
	
	local tower = TowerHandler:GetTower(towerID)
	local originalTowerData = Towers[tower.Name]
	
	local buffStacks = {}
	
	for i, buff in pairs(tower.Buffs) do
		
		--Damage, Firerate and accepted tower stats
		if tower.Stats[buff.Type] then
			buffStacks[buff.Type] += buff.Stats
		end
		
	end
	
	for buffName, increase in pairs(buffStacks) do
		tower.Stats[buffName] *= (1 + increase)
	end
end

return TowerHandler

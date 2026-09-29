--[[
    EnemyManager (ModuleScript)
    Path: ServerStorage → Modules
    Parent: Modules
    Exported: 2026-09-29 15:57:27
]]
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Configs = ServerStorage:WaitForChild("Configs")
local Enemies = require(Configs:WaitForChild("Enemies"))

local StateManager = require(script.Parent:WaitForChild("StateManager"))

local Owl = require(ReplicatedStorage.OwlKnit.Owl)

local EnemyModels = ReplicatedStorage:WaitForChild("Assets").Models.Enemies

local Values = ReplicatedStorage:WaitForChild("Values")

local Modules = ServerStorage:WaitForChild("Modules")

local function client()
	return Owl.GetService("GameService").Client
end

local function emitEnemySpawn(enemyId, spawnTime, lane, summoned)
	--send only the enemyId, spawnTime and lane
	client().EnemySpawned:FireAll(enemyId, spawnTime, lane, summoned == true)
end


local EnemyManager = {}
EnemyManager.Waypoints = {}
EnemyManager.ActiveEnemies = {}

EnemyManager.CurrentEnemyID = 0


function EnemyManager:GetEnemiesInArea(area)
	local enemiesInArea = {}
	
	for enemyId, enemyData in pairs(EnemyManager.ActiveEnemies) do
		local localPos = area.CFrame:PointToObjectSpace(enemyData.Position)
		
		local size = area.Size
		
		if math.abs(localPos.X) <= size.X / 2 
			and math.abs(localPos.Y) <= size.Y / 2 
			and math.abs(localPos.Z) <= size.Z / 2 then
			
			table.insert(enemiesInArea, enemyData)
		end
	end
	
	return enemiesInArea
end


local function spawnServerDebug(enemyId, enemyType, SpawnTime)
	local model = Instance.new("Part")
	model.Shape = "Ball"
	model.CanCollide = false
	model.Anchored = true
	model.Parent = workspace
	model.BrickColor = BrickColor.new("Really red")
	model.Transparency = 0.5

	if EnemyManager.ActiveEnemies[enemyId] then
		EnemyManager.ActiveEnemies[enemyId].model = model
	end
end

local function spawnEnemyModel(enemyId, enemyData, SpawnTime, debugTrue)
	local model = workspace.ClientEnemies:FindFirstChild(enemyId)
	local enemyType = enemyData.Name
	if not model then
		local template = EnemyModels:FindFirstChild(enemyType)
		if not template then warn("Enemy model does not exist: " .. tostring(enemyType)) return end
		model = template:Clone()
	end
	
	model.Parent = workspace.ClientEnemies
	model.Name = enemyId
	--EnemyAttributes
	model:SetAttribute("Speed", enemyData.Speed)
	model:SetAttribute("Health", enemyData.Health)
	model:SetAttribute("MaxHP", enemyData.Health)
	model:SetAttribute("EnemyName", enemyData.Name)
	
	model:SetAttribute("SpawnTime", SpawnTime)
	model:SetAttribute("LastUpdateTime", SpawnTime)

	local cframe, size = model:GetBoundingBox()

	return model, size
end


function EnemyManager:SpawnEnemy(enemyData, debugTrue, Lane)
	local enemyId = "Enemy_" .. EnemyManager.CurrentEnemyID
	

	local SpawnTime = workspace:GetServerTimeNow()
	
	local enemyModel, size = spawnEnemyModel(enemyId, enemyData, SpawnTime, true)
	emitEnemySpawn(EnemyManager.CurrentEnemyID, SpawnTime, Lane)
	EnemyManager.CurrentEnemyID += 1

	--if debugTrue then
	--	spawnServerDebug(enemyId, enemyType, SpawnTime)
	--end

	local Base = {
		Hp = enemyData.Health,
		MaxHP = enemyData.Health,
		Reward = enemyData.Reward,
		Speed = enemyData.Speed,
	}


	local enemyRef = {
		SpawnTime = SpawnTime,

		-- Units per second
		Size = size,
		Model = enemyModel,

		BaseStats = Base,

		Stats = table.clone(Base),
		Lane = Lane,

		ElapsedTime = 0,
		
		Position = EnemyManager.Waypoints[Lane][1],

		Alpha = 0,
		Waypoint = 0,
		enemyId = enemyId,

		LastUpdateTime = SpawnTime,
		BaseDistance = 0,

		Skills = {},
	}

	EnemyManager.ActiveEnemies[enemyId] = enemyRef

	if not enemyData.Skills then return end

	for name, skills in pairs(enemyData.Skills) do
		enemyRef.Skills[name] = table.clone(skills)
		enemyRef.Skills[name].LastUsed = 0
	end


	return enemyId, enemyData, SpawnTime
end

function EnemyManager:SetWaypoints(waypointData)
	EnemyManager.Waypoints = waypointData
end


function EnemyManager:GetEnemy(targetID)
	return EnemyManager.ActiveEnemies[targetID]
end


function EnemyManager:GetPositionOnPath(lane, distanceTraveled, height, enemyId)
	local waypoints = EnemyManager.Waypoints[lane]
	if not waypoints then return Vector3.zero, Vector3.zero end

	local accumulatedDistance = 0
	for i = 1, #waypoints - 1 do
		local pA = waypoints[i]
		local pB = waypoints[i + 1]
		local segmentLength = (pB - pA).Magnitude

		if accumulatedDistance + segmentLength >= distanceTraveled then
			local Alpha = (distanceTraveled - accumulatedDistance) / segmentLength
			local posRaw = pA:Lerp(pB, Alpha)
			local currentPos = Vector3.new(posRaw.X, height.Y * 0.5, posRaw.Z)
			local direction = (pB - pA).Unit

			local enemy = EnemyManager.ActiveEnemies[enemyId]
			if enemy then
				enemy.Alpha = Alpha
				enemy.Waypoint = i
				enemy.Position = currentPos -- Saved directly on table
				enemy.TotalDistance = distanceTraveled -- Robust numerical tracking
			end

			return currentPos, direction
		end
		accumulatedDistance += segmentLength
	end

	return waypoints[#waypoints], Vector3.zero -- End of path reached
end


function EnemyManager:RemoveEnemy(enemyId)

	if EnemyManager.ActiveEnemies[enemyId] then

		local enemyData = EnemyManager.ActiveEnemies[enemyId]
		local target = {
			enemyId = enemyData.enemyId,
		}
		

		EnemyManager.ActiveEnemies[enemyId] = nil

		--aclient().EnemyRemoved:FireAll(enemyId)

		--print("Enemy Removed")
	end
end



function EnemyManager:CleanupEnemies()
	EnemyManager.Heartbeat:Disconnect()
	for enemyId, data in pairs(EnemyManager.ActiveEnemies) do
		if data.Model then data.Model:Destroy() end
	end

	table.clear(EnemyManager.ActiveEnemies)

end


function EnemyManager:UpdateEnemyState(enemy, newSpeed)

	local currentTime = workspace:GetServerTimeNow()
	--wprint("Updated Enemy: ", enemy)
	--Calculate total distance accumulated up to this exact moment
	if enemy.LastUpdateTime == nil then enemy.LastUpdateTime = enemy.SpawnTime end
	
	local timePassed = currentTime - enemy.LastUpdateTime
	local distanceSinceLastUpdate = timePassed * enemy.Stats.Speed

	--Lock in new base values
	enemy.BaseDistance = enemy.BaseDistance + distanceSinceLastUpdate
	enemy.LastUpdateTime = currentTime
	enemy.Stats.Speed = newSpeed

	--Replicate updated snapshot to all clients
	client().EnemyStateChanged:FireAll(enemy.enemyId, {
		Speed = enemy.Stats.Speed,
		BaseDistance = enemy.BaseDistance,
		IsSlowed = enemy.IsSlowed == true,
		IsStunned = enemy.IsStunned == true,
	}, enemy.LastUpdateTime)


end

function EnemyManager:UpdateEnemies()

		local currentTime = workspace:GetServerTimeNow()
		for enemyId, data in pairs(EnemyManager.ActiveEnemies) do

			EnemyManager.ActiveEnemies[enemyId].ElapsedTime = currentTime - data.SpawnTime
			
			local timeSinceUpdate = currentTime - data.LastUpdateTime
			local totalDistance = data.BaseDistance + (timeSinceUpdate * data.Stats.Speed)
			
			
			--local distanceTraveled = data.ElapsedTime * data.Stats.Speed
			
			
			local pos, direction = EnemyManager:GetPositionOnPath(data.Lane, totalDistance, data.Size, enemyId)

			data.Position = pos
			data.Direction = direction
			
			if direction ~= Vector3.zero then
				--data.Hitbox.CFrame = CFrame.lookAt(pos, pos + direction)
			else

				-- Reached end of path locally (Server handles actual base damage/destroy logic)

				if data.Stats.Hp > 0 then
					StateManager:IncrementState("HP", -10)
					Values.HP.Value = StateManager:GetGlobalState("HP")
				end
				EnemyManager:RemoveEnemy(enemyId)
				continue
			end

			--Skill Handling


			--print(data.Skills)

			if not data.Skills then continue end

			local currentTime = os.clock()
			for skillName, skillData in pairs(data.Skills) do
				if currentTime - skillData.LastUsed >= skillData.Cooldown then
					skillData.LastUsed = currentTime

					if skillData.SkillFunction then skillData.SkillFunction(data) continue end

					if skillData.Type == "Summon" then

						if not skillData.Enemy then warn("Summon Enemy does not exist") continue end
						if not Enemies[skillData.Enemy] then warn("Summoned Enemy does not Exist in enemy data") continue end

						if skillData.SummonType == "SummonBurst" then

							local amount = math.random(skillData.SummonAmount[1], skillData.SummonAmount[2])
							task.spawn(function()
								for i = 1, amount do
									local currentID = EnemyManager.CurrentEnemyID 
									EnemyManager.CurrentEnemyID += 1
									EnemyManager:SummonEnemy(data, Enemies[skillData.Enemy], true, currentID)
									
									task.wait(math.random(0, 50) / 50)
								end
							end)
						else
							EnemyManager:SummonEnemy(data, Enemies[skillData.Enemy], true)
						end
					end
				end
			end
		end
end




--Skill Handlers
function EnemyManager:SummonEnemy(summoner, enemyData, debugTrue, id)
	
	local id = id or EnemyManager.CurrentEnemyID
	if not id then
		EnemyManager.CurrentEnemyID += 1
	end
	
	local enemyId = "Enemy_" .. id

	local currentTime = workspace:GetServerTimeNow()

	local offsetStuds = (summoner.Size.Z * 0.5) + 3 --calculate distance here in front of the summoner
	local summonerDistance = summoner.ElapsedTime * summoner.Stats.Speed
	local targetDistance = summonerDistance + offsetStuds
	
	local effectiveSpawnTime = currentTime - (targetDistance / enemyData.Speed)

	-- Notify clients with the offset spawn time so client render matches server
	
	local enemyModel, size = spawnEnemyModel(enemyId, enemyData, effectiveSpawnTime, true)
	emitEnemySpawn(id, effectiveSpawnTime, summoner.Lane, true)
	

	local cframe, size = enemyModel:GetBoundingBox()

	local Base = {
		Hp = enemyData.Health,
		MaxHP = enemyData.Health,
		Reward = enemyData.Reward,
		Speed = enemyData.Speed,
	}

	EnemyManager.ActiveEnemies[enemyId] = {
		Model = enemyModel,
		SpawnTime = effectiveSpawnTime,
		
		Size = size,
		BaseStats = Base,
		Stats = table.clone(Base),

		Lane = summoner.Lane,
		ElapsedTime = currentTime - effectiveSpawnTime,
		Alpha = summoner.Alpha or 0,
		Waypoint = summoner.Waypoint or 1,
		LastUpdateTime = currentTime,

		-- FIX: Set BaseDistance to targetDistance, NOT 0!
		BaseDistance = targetDistance,
		TotalDistance = targetDistance,
		Position = summoner.Position,
		enemyId = enemyId
	}

	return enemyId, enemyData, effectiveSpawnTime


end



return EnemyManager

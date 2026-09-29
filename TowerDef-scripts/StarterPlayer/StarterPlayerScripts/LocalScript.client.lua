--[[
    LocalScript (LocalScript)
    Path: StarterPlayer → StarterPlayerScripts
    Parent: StarterPlayerScripts
    Properties:
        Disabled: false
    Exported: 2026-09-29 15:57:28
]]
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Debris = game:GetService("Debris")

local Configs = ReplicatedStorage:WaitForChild("Configs")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Owl = require(ReplicatedStorage.OwlKnit.Owl)


repeat task.wait() until ReplicatedStorage:GetAttribute("OwlClientReady")
local GameService = Owl.GetService("GameService")

local ClientModules = ReplicatedStorage:WaitForChild("ClientModules")

local ModelFolder = Assets:WaitForChild("Models")
local Enemies = ModelFolder:WaitForChild("Enemies")


local ProjectileHandler = require(ClientModules:WaitForChild("ProjectileHandler"))
local CacheHandler = require(ClientModules:WaitForChild("CacheHandler"))

local Animations = require(Configs:WaitForChild("Animations"))

local HpTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

local ArcherShootAnim = Instance.new("Animation")
ArcherShootAnim.AnimationId = "rbxassetid://98788401999385"

local AnimationTracks = {}
local RotationTweens = {}

local Waypoints = { -- Ensure waypoints are sorted in order

}

local activeEnemies = {}

local function removeEnemy(enemyId)
	if not activeEnemies[enemyId] then return end
	
	local enemyModel = workspace.ClientEnemies:FindFirstChild(enemyId)
	if not enemyModel then return end 
	
	Debris:AddItem(enemyModel, 0.15)
	activeEnemies[enemyId] = nil
end

local function playAttackEffect(towerID, target, attackType, targets)
	
	local towerIDStr = "Tower_" .. towerID
	local PlayerID = CacheHandler:GetPlayerCache("PlayerID")
	local towerModel = workspace.Towers[`Player{PlayerID}`]:FindFirstChild(towerIDStr)

	if not towerModel or not target then return end

	-- Clean string check to prevent "Enemy_Enemy_X"
	local targetIdClean = tostring(target.enemyId):gsub("^Enemy_", "")
	
	local targetModel = workspace.ClientEnemies:FindFirstChild("Enemy_" .. targetIdClean)
	if not targetModel then return end

	local targetPoint = targetModel.PrimaryPart
	local root = towerModel.PrimaryPart or towerModel:FindFirstChild("HumanoidRootPart")
	if not targetPoint or not root then return end

	local towerID = towerModel:GetAttribute("TowerID")
	local oldTween = RotationTweens[towerID]
	if oldTween then oldTween:Cancel() end
	local flatTarget = Vector3.new(targetPoint.Position.X, root.Position.Y, targetPoint.Position.Z)
	local rotateTween = TweenService:Create(root, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = CFrame.lookAt(root.Position, flatTarget),
	})
	RotationTweens[towerID] = rotateTween
	rotateTween:Play()

	local humanoid = towerModel:FindFirstChildOfClass("Humanoid")
	if humanoid then
		if not AnimationTracks[towerID] then
			local config = Animations[towerModel:GetAttribute("TowerName")] or Animations.Default
			local animationID = config and config.Shoot
			if animationID then
				local animation = Instance.new("Animation")
				animation.AnimationId = "rbxassetid://" .. animationID
				local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
				AnimationTracks[towerID] = animator:LoadAnimation(animation)
			end
		end

		local track = AnimationTracks[towerID]
		if track then
			if track.IsPlaying then
				track.TimePosition = 0
			else
				track:Play(0.03)
			end
		end
	end

	if attackType == "Projectile" then
		ProjectileHandler:SingleProjectile(towerModel, targetModel)
	elseif attackType == "Chain" then
		--print("CHAIN", targets)
		ProjectileHandler:ChainLightningProjectile(towerModel, targets)
	end

	-- Update Health Bar Visuals
	local function updateBar(model, id)
		if not model then return end
		local hpBar = model:FindFirstChild("Bar")
		if hpBar then hpBar = hpBar:FindFirstChild("HP") end
		if not hpBar then return end

		local hp = model:GetAttribute("Health") or 0
		local maxHP = model:GetAttribute("MaxHP") or 1
		local HP = math.clamp(hp / maxHP, 0, 1)
		
		if hp <= 0 then
			removeEnemy("Enemy_" .. id)
		end
		TweenService:Create(hpBar.Health, TweenInfo.new(0.1), { Size = UDim2.new(HP, 0, 1, 0) }):Play()
	
		
		
	end

	if targets then
		for _, chainTarget in pairs(targets) do
			local chainedModel = workspace.ClientEnemies:FindFirstChild("Enemy_" .. chainTarget.enemyId)
			
			--print("CHAINED MODEL: ", chainTarget, chainedModel)
			updateBar(chainedModel, chainTarget.enemyId)
		end
	else
		updateBar(targetModel, targetIdClean)
	end
end



local function getPositionOnPath(waypoints, distanceTraveled, height, enemyId)
	local accumulatedDistance = 0

	for i = 1, #waypoints - 1 do
		local pA = waypoints[i]
		local pB = waypoints[i + 1]
		local segmentLength = (pB - pA).Magnitude

		if accumulatedDistance + segmentLength >= distanceTraveled then
			local alpha = (distanceTraveled - accumulatedDistance) / segmentLength
			local posRaw = pA:Lerp(pB, alpha)
			local direction = (pB - pA).Unit

			-- Calculate perpendicular (right) vector relative to the path direction
			local rightVector = direction:Cross(Vector3.yAxis)
			local enemyData = activeEnemies[enemyId]
			local lateralOffset = enemyData.lateralOffset or 0
			
			--print(lateralOffset)

			-- Apply the lateral offset perpendicular to the movement direction
			local offsetPos = posRaw + (rightVector * lateralOffset)
			local currentPos = Vector3.new(offsetPos.X, height, offsetPos.Z)


			return currentPos, direction
		end
		accumulatedDistance += segmentLength
	end

	return waypoints[#waypoints], Vector3.zero -- End of path reached
end


local function updateStatusVisuals(enemyData)
	local model = enemyData.model
	if not model then return end

	local highlight = model:FindFirstChild("StatusHighlight")
	if not highlight then
		highlight = Instance.new("Highlight")
		highlight.Name = "StatusHighlight"
		highlight.OutlineTransparency = 1
		highlight.Parent = model
	end

	if enemyData.isStunned then
		highlight.Enabled = true
		highlight.FillColor = Color3.fromRGB(255, 230, 80) -- Yellow for Stun
		highlight.FillTransparency = 0.4
	elseif enemyData.isSlowed then
		highlight.Enabled = true
		highlight.FillColor = Color3.fromRGB(80, 200, 255) -- Ice Blue for Slow
		highlight.FillTransparency = 0.5
	else
		highlight.Enabled = false
	end
end

--GameService.EnemyRemoved:Connect(function(enemyId)
--	local targetModel = workspace.ClientEnemies:FindFirstChild(enemyId)
--	if targetModel then
--		task.spawn(function()
--			task.wait(5)
--			targetModel:Destroy()
--			activeEnemies[enemyId] = nil
--		end)
		
--	end
	
--end)


GameService.EnemySpawned:Connect(function(enemyId, spawnTime, lane, summoned)
	
	local enemyId = "Enemy_" .. enemyId
	local model = workspace.ClientEnemies:WaitForChild(enemyId)

	local currentTime = workspace:GetServerTimeNow()
	local activeData = activeEnemies[enemyId]
	local lane = Waypoints[lane]
	
	local speed = model:GetAttribute("Speed") or 10

	if activeData then
		-- Calculate accumulated distance up to right now before applying new speed
		local timePassed = currentTime - activeData.lastUpdateTime
		activeData.baseDistance += timePassed * activeData.speed
		activeData.lastUpdateTime = currentTime


		activeData.speed = speed
	else
		-- Initial spawn setup
		local effectiveTime = spawnTime or currentTime
		local cframe, height = model:GetBoundingBox()

		activeData = {
			model = model,
			baseDistance = 0,
			
			lastUpdateTime = effectiveTime,
			speed = speed,
			isSlowed = false,
			isStunned = false,
			lane = lane,
			height = height.Y * 0.5,
			lateralOffset = 0
		}

		if summoned then 
			activeData.lateralOffset = (math.random() - 0.2) * 2 
		end

		activeEnemies[enemyId] = activeData
	end
	


	updateStatusVisuals(activeData)
end)


--UpdateEnemiesEvent.OnClientEvent:Connect(function(enemyId, enemyData, spawnTime, lane, summoned)

--	local model = workspace.ClientEnemies:FindFirstChild(enemyId) or Enemies:FindFirstChild(enemyData.Name):Clone()
	
--	if not model then warn("Enemy model does not exist") return end
--	model.Parent = workspace.ClientEnemies
--	model.Name = enemyId
	
--	local new_enemyData
	
--	if activeEnemies[enemyId] then
--		new_enemyData = activeEnemies[enemyId]
--		new_enemyData.speed = enemyData.Speed
		
--	else
--		new_enemyData = {
--			model = model,
--			spawnTime = spawnTime,
--			speed = enemyData.Speed, -- Units per second

--			lane = lane,
--			xOffset = math.random(-1, 1),
--			lateralOffset = 0
--		}
--	end
	
--	if summoned and not activeEnemies[enemyId] then new_enemyData.lateralOffset = (math.random() - 0.2) * 2 end
	
--	activeEnemies[enemyId] = new_enemyData
--end)

GameService.WaypointsChanged:Connect(function(waypoints)
	
	print("Client Waypoints Changed")
	Waypoints = waypoints
	print(waypoints)
end)

GameService:GetWaypoints():andThen(function(waypoints)
	Waypoints = waypoints or {}
	print("Waypoint Changed")
end):catch(warn)

--RunService.RenderStepped:Connect(function()
--	local currentTime = workspace:GetServerTimeNow()

--	for enemyId, data in pairs(activeEnemies) do
--		local elapsedTime = currentTime - data.spawnTime
--		local distanceTraveled = elapsedTime * data.speed
		
--		local size = data.model:GetExtentsSize().Y * 0.5
		
--		local pos, direction = getPositionOnPath(data.lane, distanceTraveled, size, enemyId)

--		if direction ~= Vector3.zero then
--			data.model:PivotTo(CFrame.lookAt(pos, pos + direction))
--		else
--			-- Reached end of path locally (Server handles actual base damage/destroy logic)
--			data.model:Destroy()
--			activeEnemies[enemyId] = nil
--		end
--	end
--end)


RunService.RenderStepped:Connect(function()
	local currentTime = workspace:GetServerTimeNow()

	for enemyId, data in pairs(activeEnemies) do
		-- Calculate distance deterministically from snapshot point
		local timeSinceUpdate = currentTime - data.lastUpdateTime
		local totalDistance = data.baseDistance + (timeSinceUpdate * data.speed)

		local pos, direction = getPositionOnPath(data.lane, totalDistance, data.height, enemyId)
		
		--if data.model:GetAttribute("Health") <= 0 then
		--	Debris:AddItem(data.model, 0)
		--	activeEnemies[enemyId] = nil

		--end

		if direction ~= Vector3.zero then
			data.model:PivotTo(CFrame.lookAt(pos, pos + direction))
		else
			-- Reached end of path locally
			data.model:Destroy()
			activeEnemies[enemyId] = nil
		end
	end
end)

GameService.TowerAttack:Connect(function(batch)
	for _, effect in ipairs(batch) do
		local towerID, targetID, attackType, compactTargets = effect[1], effect[2], effect[3], effect[4]
		local chainTargets
		if compactTargets then
			chainTargets = table.create(#compactTargets)
			
			
			for index, packed in ipairs(compactTargets) do
				chainTargets[index] = { enemyId = tostring(packed)}
			end
			
			--print(chainTargets, compactTargets)
		end
		
		--print(towerID, targetID, attackType, compactTargets)
		playAttackEffect(towerID, {enemyId = tostring(targetID)}, attackType, chainTargets)
	end
end)

GameService.EnemyStateChanged:Connect(function(enemyId, state, timestamp)
	local activeData = activeEnemies[enemyId]
	if not activeData then return end
	local now = workspace:GetServerTimeNow()
	activeData.baseDistance += (now - activeData.lastUpdateTime) * activeData.speed
	activeData.lastUpdateTime = timestamp or now
	activeData.speed = state.Speed or activeData.speed
	activeData.baseDistance = state.BaseDistance or activeData.baseDistance
	activeData.isSlowed = state.IsSlowed == true
	activeData.isStunned = state.IsStunned == true
	updateStatusVisuals(activeData)
end)

print(Owl)
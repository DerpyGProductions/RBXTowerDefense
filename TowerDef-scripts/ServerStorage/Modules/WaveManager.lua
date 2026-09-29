--[[
    WaveManager (ModuleScript)
    Path: ServerStorage → Modules
    Parent: Modules
    Exported: 2026-09-29 15:57:27
]]
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ServerStorage:WaitForChild("Configs")
local Levels = ServerStorage:WaitForChild("Levels")

local AssetsFolder = ReplicatedStorage:WaitForChild("Assets")
local Values = ReplicatedStorage:WaitForChild("Values")


local ModelsFolder = AssetsFolder:WaitForChild("Models")
local Enemies = ModelsFolder:WaitForChild("Enemies")


local Owl = require(ReplicatedStorage.OwlKnit.Owl)

local function client()
	return Owl.GetService("GameService").Client
end

local EnemyDataRetriever = require(script.Parent:WaitForChild("EnemyDataRetriever"))
local EnemyManager = require(script.Parent:WaitForChild("EnemyManager"))
local StateManager = require(script.Parent:WaitForChild("StateManager"))

local WaveManager = {}

local PLAYER_SCALING_MULTIPLIER = (1 + ( 0.4 * (2 - 1)))

WaveManager.CurrentLoadedLevel = nil
WaveManager.CurrentWaypoints = {}

local function initWaypoints(levelData)

	for laneIndex, lane in ipairs(levelData.Paths) do
		WaveManager.CurrentWaypoints[laneIndex] = {}
		for i = 1, #lane:GetChildren() do
			local node = lane[i]
			
			WaveManager.CurrentWaypoints[laneIndex][i] = node.Position
		end
	end
	
	print("WAYPOINTS INITIALIZED")
	EnemyManager.Waypoints = WaveManager.CurrentWaypoints
	client().WaypointsChanged:FireAll(WaveManager.CurrentWaypoints)
end

local function waveAll(enemyData, _debug)
	for i, lane in pairs(WaveManager.CurrentWaypoints) do
		local enemyId, enemyType, spawnTime = EnemyManager:SpawnEnemy(enemyData, _debug, i)
	end
end

function WaveManager:LoadLevel(level)
	local levelRef = Levels:FindFirstChild(level)
	
	if not levelRef then warn("Level " .. level .. " does not exist!") return end
	
	local levelData = require(levelRef)
	print(`Loaded level {level}`)
	--print(levelData)
	
	initWaypoints(levelData)
	
	WaveManager.CurrentLoadedLevel = levelData
	
	return levelData
end


function WaveManager:StartLevel(levelData)
	local levelData = levelData or WaveManager.CurrentLoadedLevel
	
	if not levelData then warn("No level data!") return end
	
	for waveNumber = 1, #levelData.Waves do --loops through all the waves
		local waveData = levelData.Waves[waveNumber]
		print(`Starting wave {waveNumber}`)
		--UpdateWave:FireAllClients(waveNumber)
		Values.CurrentWave.Value = waveNumber
		
		for enemy, enemyCount in pairs (waveData.Enemies) do --loops through all the enemies
			local enemyData = EnemyDataRetriever:GetEnemyData(enemy)
			if not enemyData then warn("Invalid enemy key ") continue end
			
			local enemyModel = Enemies:FindFirstChild(enemy)
			if not enemyModel then warn("Enemy model does not exist") continue end 
			
			local enemyHP = enemyData.Health * PLAYER_SCALING_MULTIPLIER * (1.20 ^ (waveNumber - 1)) * (waveNumber ^ 0.8)
			enemyData.Health = enemyHP
			
			print(`CURRENT HEALTH: {enemyHP}`)
			
			for i = 1, enemyCount do
				local enemyId, enemyType, spawnTime
				if waveData.Lane == "All" then --enemies spawn in all lanes at the same time (enemy count x2)
					enemyId, enemyType, spawnTime = waveAll(enemyData, true)
				end
				
				if StateManager:GetGlobalState("HP") <= 0 then
					return
				end
				
				task.wait(waveData.Delay)
			end
			
		end
		
		task.wait(10) --Wave Cooldown
	end
	
	
	print("GAME OVER!")
end


return WaveManager

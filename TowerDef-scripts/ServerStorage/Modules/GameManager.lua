--[[
    GameManager (ModuleScript)
    Path: ServerStorage → Modules
    Parent: Modules
    Exported: 2026-09-29 15:57:27
]]
local RunService = game:GetService("RunService")

local SummoningHandler = require(script:WaitForChild("SummoningHandler"))
local StateManager = require(script.Parent:WaitForChild("StateManager"))
local TileManager = require(script.Parent:WaitForChild("TileManager"))
local TowerHandler = require(script.Parent:WaitForChild("TowerHandler"))

local EnemyManager = require(script.Parent:WaitForChild("EnemyManager"))
local WaveManager = require(script.Parent:WaitForChild("WaveManager"))
local MapHandler = require(script.Parent:WaitForChild("MapHandler"))
local BuffHandler = require(script.Parent:WaitForChild("BuffHandler"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Owl = require(ReplicatedStorage.OwlKnit.Owl)

local GameManager = {}

local waypoints = { -- Ensure waypoints are sorted in order
	workspace.Map.Nodes.Path1["1"].Position,
	workspace.Map.Nodes.Path1["2"].Position,
	workspace.Map.Nodes.Path1["3"].Position,
	workspace.Map.Nodes.Path1["4"].Position,
	workspace.Map.Nodes.Path1["5"].Position
}


function GameManager:LoadGame(Difficulty)
	StateManager:InitStates()

	--EnemyManager:SetWaypoints(waypoints)
	WaveManager:LoadLevel(Difficulty)
	MapHandler:InitMap() 
	
end

function GameManager:StartGame()
	
	print(StateManager:GetAll())
	
	TowerHandler:InitTowerFolders()
	SummoningHandler:HandleSummonAll()
	
	TileManager:SetupTiles()
	TileManager:AdjustPlayerTiles()
	
	MapHandler:StartMap()
	
	BuffHandler:Start()
	
	
	RunService.Heartbeat:Connect(function(delta)
		EnemyManager:UpdateEnemies(delta)
		TowerHandler:UpdateTowers(delta)
	end)
	
	
	
	SummoningHandler:ListenToPlayerSummons()
	
	Owl.GetService("GameService").Client.GameStarted:FireAll()
	
	WaveManager:StartLevel()
	
	
	--Cleanup
	EnemyManager:CleanupEnemies()
	TowerHandler:StopTowers()
end

return GameManager

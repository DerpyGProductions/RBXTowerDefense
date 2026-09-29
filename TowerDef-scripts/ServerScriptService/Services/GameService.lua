--[[
    GameService (ModuleScript)
    Path: ServerScriptService → Services
    Parent: Services
    Exported: 2026-09-29 15:57:27
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Owl = require(ReplicatedStorage.OwlKnit.Owl)
local GameManager = require(ServerStorage.Modules.GameManager)
local StateManager = require(ServerStorage.Modules.StateManager)
local SummoningHandler = require(ServerStorage.Modules.GameManager.SummoningHandler)
local WaveManager = require(ServerStorage.Modules.WaveManager)

local GameService = Owl.CreateService({
	Name = "GameService",
	Middleware = {
		Inbound = {
			Owl.Util.RateLimiter.perPlayer(15, 1, "GameService"),
		},
	},
	Client = {
		
		GameClientInit = Owl.CreateSignal(),
		GameStarted = Owl.CreateSignal(),
		WaypointsChanged = Owl.CreateSignal(),
		EnemySpawned = Owl.CreateSignal(),
		EnemyStateChanged = Owl.CreateSignal(),
		EnemyRemoved = Owl.CreateSignal(),
		
		-- Reliable because attacks now arrive in a capped 12 Hz batch; dropped packets caused missing animation/turn effects.
		TowerAttack = Owl.CreateSignal({unreliable = true}),
		NextSummonChanged = Owl.CreateSignal(),
		MoneyChanged = Owl.CreateSignal(),
	},
})

GameService._started = false

function GameService:OwlInit()
	GameManager:LoadGame("Easy")
end

function GameService:OwlOnPlayerAdded(player)
	
	if WaveManager.CurrentWaypoints ~= nil then
		GameService.Client.WaypointsChanged:FireAll(WaveManager.CurrentWaypoints)
	end
	print(`{player.Name} joined the game!`)
end

function GameService.Client:StartGame(player)
	if not Owl.GetPlrToken(player) then return false end
	if GameService._started then return false end
	GameService._started = true
	task.spawn(function()
		GameManager:StartGame()
	end)
	return true
end

function GameService.Client:GetPlayerID(player)
	if not Owl.GetPlrToken(player) then return nil end
	return StateManager:GetPlayerID(player.UserId)
end

function GameService.Client:GetWaypoints(player)
	if not Owl.GetPlrToken(player) then return {} end
	return WaveManager.CurrentWaypoints
end

function GameService.Client:Summon(player)
	if not Owl.GetPlrToken(player) then return nil end
	return SummoningHandler:RequestSummon(player)
end

function GameService.Client:Merge(player, towerID)
	if not Owl.GetPlrToken(player) or type(towerID) ~= "string" then return false end
	return SummoningHandler:RequestMerge(player, towerID)
end

function GameService.Client:Swap(player, towerID, targetTile)
	if not Owl.GetPlrToken(player) or type(towerID) ~= "string" or typeof(targetTile) ~= "Instance" then
		return false
	end
	return SummoningHandler:RequestSwap(player, towerID, targetTile)
end

function GameService.Client:Upgrade(player, buffName, buffUpgrade)
	if not Owl.GetPlrToken(player) or type(buffName) ~= "string" or type(buffUpgrade) ~= "table" then
		return false
	end
	return SummoningHandler:RequestUpgrade(player, buffName, buffUpgrade)
end

return GameService
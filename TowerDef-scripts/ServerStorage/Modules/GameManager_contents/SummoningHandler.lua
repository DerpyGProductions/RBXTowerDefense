--[[
    SummoningHandler (ModuleScript)
    Path: ServerStorage → Modules → GameManager
    Parent: GameManager
    ⚠️  NESTED SCRIPT: This script is inside another script
    Exported: 2026-09-29 15:57:27
]]
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Configs = ServerStorage:WaitForChild("Configs")
local Events = ServerStorage:WaitForChild("Events")
local Owl = require(ReplicatedStorage.OwlKnit.Owl)

local StateManager = require(script.Parent.Parent:WaitForChild("StateManager"))
local LuckManager = require(script.Parent.Parent:WaitForChild("LuckManager"))
local TowerHandler = require(script.Parent.Parent:WaitForChild("TowerHandler"))
local TOWER_CONFIGS = require(Configs:WaitForChild("Towers"))

local Rarities = {"Common", "Uncommon", "Rare", "Epic", "Legendary"}
local SummoningHandler = {}
local TableLengths = {}

for rarity, data in pairs(TOWER_CONFIGS) do
	TableLengths[rarity] = #data
end

local function client()
	return Owl.GetService("GameService").Client
end

local function verifyPlayerOwnership(towerID, player)
	local tower = TowerHandler:GetTower(towerID)
	return tower ~= nil and tower.Owner == player.UserId
end

function SummoningHandler:HandleNextSummon(player)
	local playerLuck = StateManager:GetState(player.UserId, "LuckMultiplier")
	local rarity = LuckManager:GetNextSummonRarity(playerLuck)
	local rolledTower = TOWER_CONFIGS[rarity][math.random(1, TableLengths[rarity])]

	StateManager:SetState(player.UserId, "CurrentSummon", rolledTower)
	client().NextSummonChanged:Fire(player, rolledTower)
	
	return rolledTower
end

function SummoningHandler:HandleSummonAll()
	for _, player in ipairs(Players:GetPlayers()) do
		SummoningHandler:HandleNextSummon(player)
	end
end

function SummoningHandler:HandleMerge(player, mergeA, mergeB)
	local rarityIndex = table.find(Rarities, mergeA:GetAttribute("Rarity"))
	local mergedRarity = rarityIndex and Rarities[rarityIndex + 1]
	if not mergedRarity then return nil end

	local rolledTower = TOWER_CONFIGS[mergedRarity][math.random(1, TableLengths[mergedRarity])]
	local tile = TowerHandler:GetTower(mergeA:GetAttribute("TowerID")).Tile

	-- Remove both source towers before occupying the destination tile.
	TowerHandler:RemoveTower(mergeA:GetAttribute("TowerID"))
	TowerHandler:RemoveTower(mergeB:GetAttribute("TowerID"))

	if not TowerHandler:InitTower(player, rolledTower, tile) then return nil end
	return rolledTower
end

function SummoningHandler:RequestSummon(player)
	local currentSummon = StateManager:GetState(player.UserId, "CurrentSummon")
	local money = StateManager:GetState(player.UserId, "Money")
	if not currentSummon or not money or money < 30 then return nil end
	if not TowerHandler:InitTower(player, currentSummon) then return nil end

	money -= 30
	StateManager:SetState(player.UserId, "Money", money)
	client().MoneyChanged:Fire(player, money)
	SummoningHandler:HandleNextSummon(player)
	return currentSummon
end

function SummoningHandler:RequestMerge(player, towerID)
	local tower = TowerHandler:GetTower(towerID)
	if not tower or tower.Rarity == "Legendary" or not verifyPlayerOwnership(towerID, player) then
		return false
	end

	local playerID = StateManager:GetPlayerID(player.UserId)
	local towersFolder = workspace.Towers:FindFirstChild("Player" .. playerID)
	if not towersFolder then return false end

	local towerModel = tower.Model
	local mergeB
	for _, candidate in ipairs(towersFolder:GetChildren()) do
		if candidate ~= towerModel and candidate:GetAttribute("TowerName") == towerModel:GetAttribute("TowerName") then
			mergeB = candidate
			break
		end
	end
	if not mergeB then return false end

	return SummoningHandler:HandleMerge(player, towerModel, mergeB) or false
end

function SummoningHandler:RequestSwap(player, towerID, targetTile)
	local tower = TowerHandler:GetTower(towerID)
	if not tower or not verifyPlayerOwnership(towerID, player) then return false end
	return TowerHandler:SwapTowers(player, tower, targetTile) == true
end

function SummoningHandler:RequestUpgrade(player, buffName, buffUpgrade)
	if buffName ~= "TowerUpgrade" or type(buffUpgrade) ~= "table" then return false end
	Events.AddBuff:Invoke(buffName, {
		TargetType = "TargetRarityPlayer",
		Target = player.UserId,
		TargetRarity = buffUpgrade,
	}, 2)
	return true
end

function SummoningHandler:ListenToPlayerSummons()
	-- Requests are exposed by GameService.Client; no manual remotes are connected here.
end

return SummoningHandler
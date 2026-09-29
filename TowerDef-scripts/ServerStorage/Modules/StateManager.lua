--[[
    StateManager (ModuleScript)
    Path: ServerStorage → Modules
    Parent: Modules
    Exported: 2026-09-29 15:57:27
]]
local Players = game:GetService("Players")

local Values = game.ReplicatedStorage.Values

local StateManager = {}

local States = {}
local GlobalStates = {}


local function setDefaultState()
	local DefaultStates = {

		["Money"] = 100,
		["CurrentSummon"] = nil,

		["LuckMultiplier"] = 1,

		["Tiles"] = {}

	}
	
	return DefaultStates
end



local DefaultGlobalStates = {
	["HP"] = 100,
	["SummoningCost"] = 30,
	["Wave"] = 1
}

function StateManager:InitStates() --initialized all players to have states
	
	Players.PlayerAdded:Connect(function(player) --start listening to players to get their default states
		if not States[player.UserId] then
			States[player.UserId] = setDefaultState()
			print("Initialized State for " .. player.Name, States)
		end
	end)
	
	for _, player in pairs(Players:GetPlayers()) do --loop through all players and set their states
		print(player)
		States[player.UserId] = setDefaultState()
	end
	
	GlobalStates = table.clone(DefaultGlobalStates)
	Values.MaxHP.Value = GlobalStates.HP
	
	print(States, "INITIALIZING STATES")
end

function StateManager:SetState(player, key, value) --set player state based on state key
	
	if not States[player] then warn("Player does not exist in state") return end
	States[player][key] = value
	
end


function StateManager:SetStateAll(key, value)
	
	for userID, states in pairs(States) do
		states[key] = value
	end
end

function StateManager:IncrementAll(key, value)

	for userID, states in pairs(States) do
		states[key] += value
	end
end

function StateManager:GetState(player, key) --specific state
	--local player = player.UserId or player
	
	if not States[player] then warn("Player does not exist in state") return end
	return States[player][key]
end

function StateManager:GetStates(player)--all states of player
	--local player = player.UserId or player
	
	if not States[player] then warn("Player does not exist in state") return end
	return States[player]
end

function StateManager:GetPlayerID(player)

	
	if not States[player] then warn("Player does not exist in state", debug.traceback("Called from: "))  return end
	if not States[player].PlayerID then warn("Player ID has not been setup yet",debug.traceback("Called from: ")) return end
	
	return States[player].PlayerID
end


function StateManager:GetAll()
	
	return States
end



--GLOBAL STATES

function StateManager:SetGlobalState(key, value)
	GlobalStates[key] = value
end

function StateManager:IncrementState(key, value)
	GlobalStates[key] += value
end

function StateManager:GetGlobalState(key)
	return GlobalStates[key]
end

return StateManager

--[[
    Script (Script)
    Path: ServerScriptService
    Parent: ServerScriptService
    Properties:
        Disabled: true
        RunContext: Enum.RunContext.Legacy
    Exported: 2026-09-29 15:57:27
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Modules = ServerStorage:WaitForChild("Modules")

local GameManager = require(Modules:WaitForChild("GameManager"))
local StateManager = require(Modules:WaitForChild("StateManager"))

local UpdateEnemies = Remotes:WaitForChild("UpdateEnemies")
local RequestPlayerState = Remotes:WaitForChild("RequestPlayerState")

local started = false

Remotes.Start.OnServerEvent:Connect(function()
	started = true
	
	
end)

GameManager:LoadGame("Easy")

repeat task.wait(1) until started 

local enemy = workspace:WaitForChild("Slime")

local function spawnEnemy(enemyId, enemyType)
	local spawnTime = workspace:GetServerTimeNow()

	-- Fire data only, no physical instance created on server
	UpdateEnemies:FireAllClients(enemyId, enemyType, spawnTime)
	return enemyId, enemyType, spawnTime
end

RequestPlayerState.OnServerInvoke = function(player, requestKey)
	--print(player, requestKey)
	if not StateManager:GetPlayerID(player.UserId) then warn("Invalid player request, does not exist in state manager") return end

	if requestKey == "PlayerID" then --when client requests their player ID
		return StateManager:GetPlayerID(player.UserId)
	end
end



GameManager:StartGame()





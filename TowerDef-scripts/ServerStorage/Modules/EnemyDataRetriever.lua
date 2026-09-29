--[[
    EnemyDataRetriever (ModuleScript)
    Path: ServerStorage → Modules
    Parent: Modules
    Exported: 2026-09-29 15:57:27
]]
local ServerStorage = game:GetService("ServerStorage")

local Configs = ServerStorage:WaitForChild("Configs")
local EnemyData = require(Configs:WaitForChild("Enemies"))

local EnemyDataRetriever = {}

function EnemyDataRetriever:GetEnemyData(enemyName)
	local enemyData = EnemyData[enemyName]
	if not enemyData then warn("Enemy " .. enemyName .. " does not exist!") return end 
	
	return table.clone(enemyData)
end

return EnemyDataRetriever

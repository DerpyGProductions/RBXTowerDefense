--[[
    CacheHandler (ModuleScript)
    Path: ReplicatedStorage → ClientModules
    Parent: ClientModules
    Exported: 2026-09-29 15:57:27
]]
local CacheHandler = {}

CacheHandler.TowerCache = {}
CacheHandler.PlayerCache = {}

function CacheHandler:CacheTower(towerName, towerData)

	CacheHandler.TowerCache[towerName] = towerData
	--print("Cached tower data for", towerName)
end

function CacheHandler:GetCache(towerName)
	if not CacheHandler.TowerCache[towerName] then warn("No cache for tower" .. towerName, debug.traceback("Called from: ")) return end
	return CacheHandler.TowerCache[towerName]
end

function CacheHandler:CachePlayerData(key, value)
	CacheHandler.PlayerCache[key] = value
end

function CacheHandler:GetPlayerCache(key)
	return CacheHandler.PlayerCache[key]
end


function CacheHandler:GetCacheList()
	
	return CacheHandler.TowerCache
end

return CacheHandler


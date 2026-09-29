--[[
    IsPlayer (ModuleScript)
    Path: ReplicatedStorage → OwlKnit → Libs → DataStore2
    Parent: DataStore2
    ⚠️  NESTED SCRIPT: This script is inside another script
    Exported: 2026-09-29 15:57:27
]]
-- This function is monkey patched to return MockDataStoreService during tests
local IsPlayer = {}

function IsPlayer.Check(object)
	return typeof(object) == "Instance" and object.ClassName == "Player"
end

return IsPlayer

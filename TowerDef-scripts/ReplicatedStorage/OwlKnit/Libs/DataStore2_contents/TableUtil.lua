--[[
    TableUtil (ModuleScript)
    Path: ReplicatedStorage → OwlKnit → Libs → DataStore2
    Parent: DataStore2
    ⚠️  NESTED SCRIPT: This script is inside another script
    Exported: 2026-09-29 15:57:27
]]
local TableUtil = {}

function TableUtil.clone(tbl)
	local clone = {}

	for key, value in pairs(tbl) do
		if typeof(value) == "table" then
			clone[key] = TableUtil.clone(value)
		else
			clone[key] = value
		end
	end

	return clone
end

return TableUtil

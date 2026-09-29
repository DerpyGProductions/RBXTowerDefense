--[[
    Constants (ModuleScript)
    Path: ReplicatedStorage → OwlKnit → Libs → DataStore2
    Parent: DataStore2
    ⚠️  NESTED SCRIPT: This script is inside another script
    Exported: 2026-09-29 15:57:27
]]
local function symbol(text)
	local symbol = newproxy(true)
	getmetatable(symbol).__tostring = function()
		return text
	end
	return symbol
end

return {
	SaveFailure = {
		BeforeSaveError = symbol("BeforeSaveError"),
		DataStoreFailure = symbol("DataStoreFailure"),
		InvalidData = symbol("InvalidData"),
	}
}

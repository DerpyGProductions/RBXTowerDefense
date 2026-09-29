--[[
    GameController (ModuleScript)
    Path: StarterPlayer → StarterPlayerScripts → Controllers
    Parent: Controllers
    Exported: 2026-09-29 15:57:28
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Owl = require(ReplicatedStorage.OwlKnit.Owl)

local GameController = Owl.CreateController({
	Name = "GameController",
	Dependencies = {},
})

function GameController:OwlInit()
	self.GameService = Owl.GetService("GameService")
end

return GameController
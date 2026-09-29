--[[
    OwlInit (LocalScript)
    Path: StarterPlayer → StarterPlayerScripts
    Parent: StarterPlayerScripts
    Properties:
        Disabled: false
    Exported: 2026-09-29 15:57:28
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayerScripts = script.Parent

local Owl = require(ReplicatedStorage.OwlKnit.Owl)

Owl.AddControllers(StarterPlayerScripts.Controllers)
Owl.Start():andThen(function()
	ReplicatedStorage:SetAttribute("OwlClientReady", true)
	
	print(Owl.GetService("GameService"))
	print("OwlKnit client started")


end):catch(warn)
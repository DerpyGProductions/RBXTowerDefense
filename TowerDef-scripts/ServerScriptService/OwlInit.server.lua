--[[
    OwlInit (Script)
    Path: ServerScriptService
    Parent: ServerScriptService
    Properties:
        Disabled: false
        RunContext: Enum.RunContext.Legacy
    Exported: 2026-09-29 15:57:27
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Owl = require(ReplicatedStorage.OwlKnit.Owl)

Owl.AddServices(ServerScriptService.Services)
Owl.Start({
	Verbose = true,
	GlobalMiddleware = {
		Inbound = {
			Owl.Util.RateLimiter.perPlayer(30, 1, "Global"),
		},
	},
}):andThen(function()
	print("OwlKnit server started")
end):catch(warn)
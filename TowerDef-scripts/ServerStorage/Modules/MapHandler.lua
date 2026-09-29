--[[
    MapHandler (ModuleScript)
    Path: ServerStorage → Modules
    Parent: Modules
    Exported: 2026-09-29 15:57:27
]]
local Players = game:GetService("Players")

local TileManager = require(script.Parent.TileManager)
local StateManager = require(script.Parent.StateManager)

local MapHandler = {}

local CurrentMap = workspace.Map

local TileOwnerships = {}

local ClaimParts = {}


local thumbType = Enum.ThumbnailType.HeadShot -- Options: HeadShot, AvatarBust, AvatarThumbnail
local thumbSize = Enum.ThumbnailSize.Size420x420

local function handleClaiming(player, tileSet)
	if TileOwnerships[tileSet].Owner ~= nil then return end
	
	if StateManager:GetState(player.UserId, "PlayerID") then return end --check to see if the palyer has already claimed a tile set
	
	TileOwnerships[tileSet].Owner = player.UserId
	StateManager:SetState(player.UserId, "PlayerID", tileSet)
	
	return true
end

function MapHandler:InitMap()
	
	for i = 1, 4 do
		local tiles = CurrentMap:FindFirstChild("Player" .. i)
		if not tiles then warn("No Tile Folder for Player " .. i) continue end
		
		TileOwnerships[i] = {}
		
		TileOwnerships[i].Owner = nil
		
		local claim = tiles:FindFirstChild("Claim")
		if not claim then warn("No Claim Tile for Player " .. i) continue end
		
		claim.Transparency = 1
		claim.CanCollide = false
		claim.CanTouch = false
		claim.CanQuery = false
		
		table.insert(ClaimParts, claim)
		
		--set the proximity prompts for claiming
		claim.ProximityPrompt.Triggered:Connect(function(player)
			
			local success = handleClaiming(player, claim:GetAttribute("Player"))
			if not success then return end
			
			local content, isReady = Players:GetUserThumbnailAsync(player.UserId, thumbType, thumbSize)
			if not isReady then warn("Failed to get user thumbnail") return end
			
			claim.BillboardGui.ImageLabel.Image = content
			
			claim.ProximityPrompt:Destroy()
		end)
		
	end
	
end


function MapHandler:StartMap()
	
	--clean up the proximity prompts
	
	for i, claimPart in pairs(ClaimParts) do
		
		if claimPart:FindFirstChild("ProximityPrompt") then 
			claimPart.ProximityPrompt:Destroy()
		end
	end

	
end


return MapHandler

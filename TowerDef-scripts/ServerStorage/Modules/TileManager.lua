--[[
    TileManager (ModuleScript)
    Path: ServerStorage → Modules
    Parent: Modules
    Exported: 2026-09-29 15:57:27
]]
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local StateManager = require(script.Parent:WaitForChild("StateManager"))

local Tiles = workspace.Map 
local TileManager = {}


function TileManager:SetupTiles()
	
	for i, player in pairs(Players:GetPlayers()) do
		local playerID = StateManager:GetPlayerID(player.UserId)
		local playerFolder = Tiles["Player" .. playerID]
		
		print(playerFolder)
		
		for _, tile in pairs(playerFolder:GetChildren()) do
			if tile.Name == "Claim" then continue end
			CollectionService:AddTag(tile, `Player{playerID}Unplaced`)
			CollectionService:AddTag(tile, `Player{playerID}Tile`)
		end
		
		--StateManager:SetState(player.UserId, "PlayerID", i)
	end 
end

local function mergeTiles(targetPlayerID, sourcePlayerID)
	if targetPlayerID == sourcePlayerID then return end

	local targetFolder = Tiles:FindFirstChild("Player" .. targetPlayerID)
	local sourceFolder = Tiles:FindFirstChild("Player" .. sourcePlayerID)

	if not targetFolder or not sourceFolder then return end
	
	local claim = targetFolder.Claim
	local middle = (claim.Position + sourceFolder.Claim.Position) / 2

	claim.Position = middle

	for _, tile in pairs(sourceFolder:GetChildren()) do
		if tile.Name == "Claim" then continue end
		tile.Parent = targetFolder

		-- re-tag tiles so the target player can place towers on them
		CollectionService:RemoveTag(tile, `Player{sourcePlayerID}Tile`)
		CollectionService:RemoveTag(tile, `Player{sourcePlayerID}Unplaced`)

		CollectionService:AddTag(tile, `Player{targetPlayerID}Tile`)
		CollectionService:AddTag(tile, `Player{targetPlayerID}Unplaced`)
	end

	sourceFolder:Destroy()
end

function TileManager:AdjustPlayerTiles()
	local players = Players:GetPlayers()
	local playerCount = #players

	if playerCount == 1 then
		local activeID = StateManager:GetState(players[1].UserId, "PlayerID")

		if activeID == 1 or activeID == 2 then
			-- Merge side 1 & 2 into active player
			local targetID = (activeID == 1) and 1 or 2
			local sourceID = (activeID == 1) and 2 or 1
			mergeTiles(targetID, sourceID)
		elseif activeID == 3 or activeID == 4 then
			-- Merge side 3 & 4 into active player
			local targetID = (activeID == 3) and 3 or 4
			local sourceID = (activeID == 3) and 4 or 3
			mergeTiles(targetID, sourceID)
		end
		
		StateManager:SetStateAll("Money", 150) --set summoning money to 150 if it's duos

	elseif playerCount == 2 then
		-- Map players based on their assigned state slot
		local p1_ID = StateManager:GetState(players[1].UserId, "PlayerID")
		local p2_ID = StateManager:GetState(players[2].UserId, "PlayerID")

		-- Player 1 merges Player 2's folder
		mergeTiles(p1_ID, 2)
		mergeTiles(p1_ID, 1)

		-- Player 2 merges Player 3 & 4 folders
		mergeTiles(p2_ID, 3)
		mergeTiles(p2_ID, 4)
	end
end


function TileManager:GetPlayerTiles(player)
	local tag = `Player{StateManager:GetState(player.UserId, "PlayerID")}Tile`
	
	return CollectionService:GetTagged(tag)
end

function TileManager:GetUnplacedTiles(player)
	local tag = `Player{StateManager:GetState(player.UserId, "PlayerID")}Unplaced`
	
	return CollectionService:GetTagged(tag)
end

function TileManager:SetPlacedTile(player, tile)
	local tag = `Player{StateManager:GetState(player.UserId or player, "PlayerID")}`
	
	if tile:HasTag(tag .. "Unplaced") then --check if the tile has placed tag
		tile:RemoveTag(tag .. "Unplaced")
		tile:AddTag(tag .. "Placed")
	else
		warn("Tile is already unplaced", debug.traceback("Called from: "))
		--debug.traceback("Called from: ")
	end
end

function TileManager:SwapTile(player, tile1, tile2)
	local tag = `Player{StateManager:GetState(player.UserId or player, "PlayerID")}`
	
	local states = {
		[false] = tag .. "Unplaced", --translates placed and unplaced into boolean
		[true] = tag .. "Placed"
	}
	
	
	local tile1Bool, tile2Bool
	if tile1:HasTag(tag .. "Unplaced") then tile1Bool = false else tile1Bool = true end
	if tile2:HasTag(tag .. "Unplaced") then tile2Bool = false else tile2Bool = true end
	
	
	
	if tile1Bool ~= tile2Bool then --one tile is not occupied while the other is
		tile1:RemoveTag(states[tile1Bool])
		tile2:RemoveTag(states[tile2Bool])
		
		tile1:AddTag(states[not tile1Bool])
		tile2:AddTag(states[not tile2Bool])
		
	end
	
	--print(`SWAPPED {tile1.Name} and {tile2.Name}`, tile1:GetTags(), tile2:GetTags())
	
end

function TileManager:SetUnplacedTile(player, tile)
	local tag = `Player{StateManager:GetState(player, "PlayerID")}`

	if tile:HasTag(tag .. "Placed") then --check if the tile has placed tag
		tile:RemoveTag(tag .. "Placed")
		tile:AddTag(tag .. "Unplaced")
	else
		warn("Tile is already unplaced", debug.traceback("Function called from: "))
	end
end



return TileManager

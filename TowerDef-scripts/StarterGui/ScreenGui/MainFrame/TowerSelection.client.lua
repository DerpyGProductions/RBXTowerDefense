--[[
    TowerSelection (LocalScript)
    Path: StarterGui → ScreenGui → MainFrame
    Parent: MainFrame
    Properties:
        Disabled: false
    Exported: 2026-09-29 15:57:28
]]
local Player = game.Players.LocalPlayer

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Owl = require(ReplicatedStorage.OwlKnit.Owl)
repeat task.wait() until ReplicatedStorage:GetAttribute("OwlClientReady")
local GameService = Owl.GetService("GameService")

local AssetsFolder = ReplicatedStorage:WaitForChild("Assets")
local ModulesFolder = ReplicatedStorage:WaitForChild("ClientModules")

local ModelsFolder = AssetsFolder:WaitForChild("Models")
local UIFolder = AssetsFolder:WaitForChild("UI")

local TowersFolder = ModelsFolder:WaitForChild("Towers")

local TowerSelection = UIFolder:WaitForChild("TowerSelection")



local RaycastHandler = require(ModulesFolder:WaitForChild("RaycastHandler"))
local CacheHandler = require(ModulesFolder:WaitForChild("CacheHandler"))

local SummonButton = script.Parent.TowerSelect.Summon
local StatsFrame = script.Parent.Stats
local TowerInfo = StatsFrame:WaitForChild("TowerInfo")
local MergeButton = script.Parent.Merge

local CurrentHighlightedTower = nil
local CurrentSelectedTower = nil

local RangePopupTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local HighlightedDuplicates = {}

local HighlightColors = {
	Color3.new(1,1,1), --1 duplicate
	Color3.new(0, 1, 0.2), --2 duplicates
	Color3.new(1, 0.619608, 0.0823529),
	Color3.new(0.85098, 0, 1)
}

local function clearHighlight()
	if CurrentHighlightedTower then
		local highlight = CurrentHighlightedTower:FindFirstChild("Highlight")
		if highlight then
			highlight:Destroy()
		end
		CurrentHighlightedTower = nil
	end
end

--apply the highlight to the tower
local function highlightTower(towerModel)
	
	if CurrentHighlightedTower == towerModel then return end
	
	clearHighlight()
	
	local highlight = Instance.new("Highlight")
	highlight.Parent = towerModel
	highlight.FillTransparency = 0.5
	highlight.FillColor = Color3.new(1, 1, 1)
	highlight.OutlineTransparency = 0.5
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Enabled = true
	
	CurrentHighlightedTower = towerModel
end


local function checkDuplicateTower(towerModel) --client check if there is duplicate tower 
	local TowersFolder = workspace.Towers[`Player{CacheHandler:GetPlayerCache("PlayerID")}`]
	
	local duplicateFound = false
	for _, tower in pairs(TowersFolder:GetChildren()) do
		if towerModel:GetAttribute("TowerID") == tower:GetAttribute("TowerID") then continue end
		if towerModel:GetAttribute("TowerName") == tower:GetAttribute("TowerName") then duplicateFound = true break end
	end
	return duplicateFound
end

local function ClearHighlightDuplicateTowers()
	for name, towerGroup in pairs(HighlightedDuplicates) do
		for _, tower in pairs(towerGroup) do
			if tower:FindFirstChild("Duplicate") then
				tower.Duplicate:Destroy()
			end
		end
	end
	
	table.clear(HighlightedDuplicates)
end

local function HighlightDuplicateTowers()
	local TowersFolder = workspace.Towers[`Player{CacheHandler:GetPlayerCache("PlayerID")}`]
	
	ClearHighlightDuplicateTowers()
	for _, tower in pairs(TowersFolder:GetChildren()) do
		if not HighlightedDuplicates[tower.Name] then HighlightedDuplicates[tower.Name] = {} end
		table.insert(HighlightedDuplicates[tower.Name], tower)
	end
	
	for name, towerGroup in pairs(HighlightedDuplicates) do
		if #towerGroup > 1 then --highlight the duplicated tower
			print(#towerGroup)
			for i, towerModel in pairs(towerGroup) do
				
				
				local highlight = Instance.new("Highlight")
				highlight.Name = "Duplicate"
				highlight.Parent = towerModel
				highlight.FillTransparency = 1
				highlight.OutlineColor = HighlightColors[#towerGroup - 1] or HighlightColors[4]
				highlight.OutlineTransparency = 0
				highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				highlight.Enabled = true
			end
		else
			HighlightedDuplicates[name] = nil
		end
	end
end

local function refreshRaycastInstances() --refreshes towers for raycast inclusion
	local playerID = CacheHandler:GetPlayerCache("PlayerID")

	if not playerID then return end
	
	--get tower folder here
	local towerFolder = workspace.Towers:FindFirstChild(`Player{playerID}`)
	if not towerFolder then return end
	
	local towers = towerFolder:GetChildren()
	RaycastHandler:SetRaycastInstances(towers)
	
	HighlightDuplicateTowers()
end

local function setTowerUnselected()
	if not CurrentSelectedTower then return end

	-- Capture the specific instance we want to close right now
	local towerToClosing = CurrentSelectedTower
	CurrentSelectedTower = nil

	local rangeIndicator = towerToClosing:FindFirstChild("Range") 
	if not rangeIndicator then return end

	rangeIndicator.Size = rangeIndicator:GetAttribute("Size") or Vector3.new(10, 1, 10)
	rangeIndicator.Transparency = 0.7

	local rangeTween = TweenService:Create(rangeIndicator, RangePopupTweenInfo, {Size = Vector3.zero})
	rangeTween:Play()

	rangeTween.Completed:Wait()

	if CurrentSelectedTower ~= towerToClosing then
		rangeIndicator.Transparency = 1
	end

end

local function setTowerSelected(towerModel)
	-- 1. If clicking the exact same tower that's already open, do nothing
	if CurrentSelectedTower == towerModel then return end

	-- 2. If a different tower was open, close it first
	if CurrentSelectedTower ~= nil then 
		setTowerUnselected() 
	end

	local rangeIndicator = towerModel:FindFirstChild("Range")
	if not rangeIndicator then return end

	-- Set this tower as our active selection
	CurrentSelectedTower = towerModel

	-- Reset size to zero and make it visible to prepare for popup animation
	rangeIndicator.Size = Vector3.zero
	rangeIndicator.Transparency = 0.7

	local targetSize = rangeIndicator:GetAttribute("Size") or Vector3.new(10, 1, 10)
	local rangeTween = TweenService:Create(rangeIndicator, RangePopupTweenInfo, {Size = targetSize})

	rangeTween:Play()
end


local function setTowerInfo(towerData)
	if not towerData then return end
	
	print(towerData)
	TowerInfo.TowerName.Text = towerData.Name
	TowerInfo.Attack.Text = `ATK: {towerData.Stats.Damage}`
	TowerInfo.Firerate.Text = `RANGE: {towerData.Stats.Firerate}`
	TowerInfo.Range.Text = `RANGE: {towerData.Stats.Range}`
	
	StatsFrame.Visible = true
end





SummonButton.MouseButton1Click:Connect(function()
	GameService:Summon():andThen(function(summoned)
		if not summoned then return end
		CacheHandler:CacheTower(summoned.Name, summoned)
		refreshRaycastInstances()
	end):catch(warn)
end)




MergeButton.MouseButton1Click:Connect(function()
	local towerModel = CurrentSelectedTower
	
	if not towerModel then return end
	if towerModel:GetAttribute("Rarity") == "Legendary" then return end --max rarity
	
	local duplicateFound = checkDuplicateTower(towerModel)
	
	if duplicateFound then
		GameService:Merge(towerModel:GetAttribute("TowerID")):andThen(function(rolled)
			if not rolled then return end
			refreshRaycastInstances()
			HighlightDuplicateTowers()
			CacheHandler:CacheTower(rolled.Name, rolled)
		end):catch(warn)
	end
	
	MergeButton.Visible = false
end)



--UpdateWaveEvent.OnClientEvent:Connect(function(wave)
--	script.Parent.CurrentWave.Text = `Wave: {wave}`
--end)

script.Parent.TextButton.MouseButton1Click:Connect(function()
	script.Parent.TextButton.Visible = false
	GameService:StartGame():catch(warn)
end)


GameService.GameStarted:Connect(function()
	GameService:GetPlayerID():andThen(function(playerID)
		if not playerID then return end
		CacheHandler:CachePlayerData("PlayerID", playerID)
		local tilesFolder = workspace.Map:FindFirstChild("Player" .. playerID)
		if not tilesFolder then return end
		tilesFolder.Claim.BillboardGui.Enabled = false
		for _, tile in ipairs(tilesFolder:GetChildren()) do
			if tile.Name ~= "Claim" then
				local highlight = Instance.new("Highlight")
				highlight.FillTransparency = 1
				highlight.OutlineColor = Color3.new(1, 1, 1)
				highlight.OutlineTransparency = 0.4
				highlight.DepthMode = Enum.HighlightDepthMode.Occluded
				highlight.Adornee = tile
				highlight.Parent = tile
			end
		end
	end):catch(warn)
end)





----DRAGGING



local isDragging = false
local dragStartTower = nil
local hoverTargetTile = nil

local dragStartMousePos = nil

--create the beam
local dragAttachment0 = Instance.new("Attachment")
local dragAttachment1 = Instance.new("Attachment")
dragAttachment1.Parent = workspace.Terrain

local dragBeam = Instance.new("Beam")
dragBeam.Attachment0 = dragAttachment0
dragBeam.Attachment1 = dragAttachment1
dragBeam.Width0 = 0.4
dragBeam.Width1 = 0.2
dragBeam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
dragBeam.FaceCamera = true
dragBeam.LightEmission = 1
dragBeam.Enabled = false
dragBeam.Parent = workspace.Terrain


local LastClicked = nil
local GhostModel = nil

local function setTowerModelGhost(towerModel)
	
	if GhostModel then GhostModel:Destroy() end
	local ghostModel = towerModel:Clone()
	for _, part in pairs(ghostModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = 0.8
			part.CanCollide = false
			part.CanQuery = false
			
			part.Anchored = true
		elseif part:IsA("Decal") or part:IsA("Texture") then
			part.Transparency = 0.8
		end
	end

	ghostModel.Parent = workspace
	return ghostModel
end

-- Helper function to find and snap to nearest player tile under mouse
local function getTileUnderMouse()
	local playerID = CacheHandler:GetPlayerCache("PlayerID")
	if not playerID then return nil, nil end

	local tilesFolder = workspace.Map:FindFirstChild("Player" .. playerID)
	if not tilesFolder then return nil, nil end

	-- Get 3D mouse position in world space
	local mousePos = UserInputService:GetMouseLocation()
	local unitRay = workspace.CurrentCamera:ViewportPointToRay(mousePos.X, mousePos.Y)
	local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500)

	if raycastResult and raycastResult.Instance then
		local hitInstance = raycastResult.Instance
		if hitInstance.Parent == tilesFolder and hitInstance.Name ~= "Claim" then
			return hitInstance, hitInstance.Position + Vector3.new(0, 0.5, 0)
		end
	end

	-- Fallback: Snap to nearest tile within range
	local groundPoint = unitRay.Origin + (unitRay.Direction * (math.abs(unitRay.Origin.Y) / math.abs(unitRay.Direction.Y)))
	local closestTile = nil
	local closestDist = 8 -- Max snap distance threshold in studs

	for _, tile in pairs(tilesFolder:GetChildren()) do
		if tile.Name == "Claim" or not tile:IsA("BasePart") then continue end
		local dist = (Vector3.new(tile.Position.X, 0, tile.Position.Z) - Vector3.new(groundPoint.X, 0, groundPoint.Z)).Magnitude
		if dist < closestDist then
			closestDist = dist
			closestTile = tile
		end
	end

	if closestTile then
		return closestTile, closestTile.Position + Vector3.new(0, 0.5, 0)
	end

	return nil, groundPoint
end

RunService.RenderStepped:Connect(function(delta) --continous raycast for tower highlight bleh
	
	if isDragging then return end

	local mouseRay = RaycastHandler:UpdateMouseRaycast()

	if not mouseRay or mouseRay.Name == "Range" then clearHighlight() return end
	local towerModel = mouseRay:FindFirstAncestorWhichIsA("Model")

	if not towerModel or not towerModel:GetAttribute("TowerID") then
		clearHighlight()
		return
	end

	highlightTower(towerModel)
end)


-- Update line position continuously on RenderStepped while dragging
UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
	if not isDragging or not dragStartTower then return end
	
	dragBeam.Enabled = true
	StatsFrame.Visible = false 
	clearHighlight() 
	setTowerUnselected()

	local targetTile, targetPos = getTileUnderMouse()
	hoverTargetTile = targetTile

	if targetPos then
		dragAttachment1.WorldPosition = targetPos
		if GhostModel then
			GhostModel:PivotTo(CFrame.new(targetPos))
		end
	end
end)


-- Handle Drag Start
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local mouseRay = RaycastHandler:UpdateMouseRaycast()
		
		dragStartMousePos = UserInputService:GetMouseLocation()
		if not mouseRay or mouseRay.Name == "Range" then LastClicked = nil return end
		
		local towerModel = mouseRay:FindFirstAncestorWhichIsA("Model")
		
		if not towerModel then LastClicked = nil return end
		if not towerModel:GetAttribute("TowerID") then LastClicked = nil return end
		if towerModel:GetAttribute("Moving") then LastClicked = nil return end
		
		LastClicked = towerModel
		
		
		
		if towerModel and towerModel:FindFirstChild("HumanoidRootPart") or towerModel and towerModel.PrimaryPart then
			isDragging = true
			dragStartTower = towerModel

			local rootPart = towerModel.PrimaryPart or towerModel:FindFirstChild("HumanoidRootPart") or towerModel:FindFirstChildOfClass("BasePart")
			dragAttachment0.Parent = rootPart
			dragAttachment0.Position = Vector3.new(0, 1, 0)

			GhostModel = setTowerModelGhost(towerModel)
		end
	end
end)

-- Handle Drag End & Swap Request
UserInputService.InputEnded:Connect(function(input, gameProcessed)
	
	task.wait()
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		
		local wasActualDrag = false
		local distance = (UserInputService:GetMouseLocation() - dragStartMousePos).Magnitude

		if distance >= 5 then
			wasActualDrag = true -- Store if the mouse actually moved while dragging
		end

		if isDragging then
			-- Beam cleanup
			dragBeam.Enabled = false
			dragAttachment0.Parent = nil

			if wasActualDrag and dragStartTower and hoverTargetTile then
				-- Send swap request to server
				GameService:Swap(dragStartTower:GetAttribute("TowerID"), hoverTargetTile):catch(warn)
			end

			isDragging = false
			dragStartTower = nil
			hoverTargetTile = nil
		end

		if GhostModel then 
			GhostModel:Destroy() 
			GhostModel = nil 
		end

		-- If the player actually dragged and dropped, exit without opening selection UI
		if wasActualDrag then
			LastClicked = nil
			return
		end
		
		-- Normal click selection logic
		if not LastClicked or LastClicked.Name == "Range" then 
			StatsFrame.Visible = false 
			clearHighlight() 
			setTowerUnselected() 
			LastClicked = nil
			return 
		end


		local towerModel = LastClicked
		setTowerSelected(towerModel)
		MergeButton.Visible = checkDuplicateTower(towerModel)

		local towerData = CacheHandler:GetCache(towerModel:GetAttribute("TowerName"))
		if towerData then setTowerInfo(towerData) end

		LastClicked = nil
	end
end)
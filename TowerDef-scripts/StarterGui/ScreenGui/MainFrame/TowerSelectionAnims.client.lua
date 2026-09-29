--[[
    TowerSelectionAnims (LocalScript)
    Path: StarterGui → ScreenGui → MainFrame
    Parent: MainFrame
    Properties:
        Disabled: false
    Exported: 2026-09-29 15:57:28
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Values = ReplicatedStorage:WaitForChild("Values")
local Owl = require(ReplicatedStorage.OwlKnit.Owl)
repeat task.wait() until ReplicatedStorage:GetAttribute("OwlClientReady")
local GameService = Owl.GetService("GameService")

local CurrentWave = script.Parent.CurrentWave
local TowerSelect = script.Parent.TowerSelect
local MoneyFrame = script.Parent.Money
local MergeButton = script.Parent.Merge
local CurWaveShadow = script.Parent.CurrentWaveShadow
local Time = script.Parent.Time
local Health = script.Parent.Health
local Upgrade = script.Parent.Upgrade

local OpenUpgrade = script.Parent.OpenUpgrade

local ViewportHolder = TowerSelect:WaitForChild("ViewportHolder")
local ViewportFrame = ViewportHolder:WaitForChild("Viewport")

local PopInTweenInfo = TweenInfo.new()

local RotationConnection

--Initial Hiding of Frames
CurrentWave.Visible = false
MoneyFrame.Visible = false
TowerSelect.Visible = false
MergeButton.Visible = false
CurWaveShadow.Visible = false
Health.Visible = false
OpenUpgrade.Visible = false

Time.Visible = false

local UpgradePosition = UDim2.new(0.51, 0,0.937, 0)

local StartTime = 0

local function popTween(duration, instance, scale)
	
	local scale = scale or 1.15
	local duration = duration * 0.5
	
	local popTweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	local popOutTweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out )

	if instance:GetAttribute("OrigSize") == nil then
		instance:SetAttribute("OrigSize", instance.Size)
	end
	
	local originalSize = instance:GetAttribute("OrigSize")
	
	local enlargedSize = UDim2.new(originalSize.X.Scale * scale, originalSize.X.Offset, originalSize.Y.Scale * scale, originalSize.Y.Offset)
	
	local popInTween = TweenService:Create(instance, popTweenInfo, {Size = enlargedSize})
	local popOutTween = TweenService:Create(instance, popOutTweenInfo, {Size = originalSize})
	
	
	task.spawn(function()
		popInTween:Play()
		popInTween.Completed:Wait()
		popOutTween:Play()
		
	end)
end


local function slideToPos(instance, pos)
	task.spawn(function()
		local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		
		local tween = TweenService:Create(instance, tweenInfo, {Position = pos})
		tween:Play()
	end)
	
end


local function onHoverButton(button, targetSize)

	--
	
	task.spawn(function()
		
		button.AnchorPoint = Vector2.new(0.5, 0.5)
		if button:GetAttribute("OrigSize") == nil then
			button:SetAttribute("OrigSize", button.Size)
		end

		local originalSize = button:GetAttribute("OrigSize")
		local originalRotation = button.Rotation

		local hoverScale = 1.1 
		local rockAngle = 5    -- Degrees to rotate left and right
		local tweenTime = 0.25  -- Time to complete one transition

		-- Tween Infos
		local infoIn = TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local infoOut = TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		--local infoRock = TweenInfo.new(tweenTime * 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

		local sizeUpTween = TweenService:Create(button, infoIn, {
			Size = UDim2.new(originalSize.X.Scale * hoverScale, originalSize.X.Offset * hoverScale, originalSize.Y.Scale * hoverScale, originalSize.Y.Offset * hoverScale)
		})

		local sizeDownTween = TweenService:Create(button, infoOut, {
			Size = originalSize,
			Rotation = originalRotation
		})

		-- Handle the continuous rocking rotation
		--button.Rotation = -rockAngle -- Start slightly tilted left
		--local rockTween = TweenService:Create(button, infoRock, {Rotation = rockAngle})

		-- Track hover state
		local isHovering = false

		button.MouseEnter:Connect(function()
			
			button.Rotation = math.random(-1, 1)
			isHovering = true
			sizeDownTween:Cancel() -- Stop shrinking if it was in progress

			sizeUpTween:Play()
			--rockTween:Play() -- Starts looping left and right
		end)

		button.MouseLeave:Connect(function()
			isHovering = false
			sizeUpTween:Cancel() -- Stop growing
			--rockTween:Cancel()   -- Stop rocking

			sizeDownTween:Play() -- Shrink and reset rotation
		end)
		
		button.MouseButton1Click:Connect(function()
			--sizeDownTween:Play()
			--button.Size = originalSize
			--sizeUpTween:Cancel()
			
			popTween(0.25, button, 1.5)
		end)
		
	end)

	

	
end

--Wave Indicator
Values.CurrentWave:GetPropertyChangedSignal("Value"):Connect(function()
	
	local wave = Values.CurrentWave.Value
	popTween(0.25, CurrentWave.Label)
	
	CurrentWave.Label.Text = `Wave {wave}`
end)

--Money
GameService.MoneyChanged:Connect(function(money)
	popTween(0.25, MoneyFrame.Label)
	script.Parent.Money.Label.Text = money
end)


--set the ui to update based on the next rolled summon
GameService.NextSummonChanged:Connect(function(currentSummon)
	
	if RotationConnection then RotationConnection:Disconnect() end

	local summonModel = ReplicatedStorage.Assets.Models.Towers[currentSummon.Rarity]:FindFirstChild(currentSummon.Name)
	if not summonModel then
		summonModel = workspace.Slime
	end

	if ViewportFrame:FindFirstChild("ViewModel") then
		ViewportFrame["ViewModel"]:Destroy()
	end

	summonModel = summonModel:Clone()
	summonModel.Parent = ViewportFrame
	summonModel.Name = "ViewModel"

	summonModel:PivotTo(CFrame.new(0, 0.5, 0) )
	--print("Summoned", rolledTower)
	
	
	RotationConnection = RunService.RenderStepped:Connect(function(dt)
		if not summonModel or not summonModel.Parent then
			RotationConnection:Disconnect()
			return
		end

		-- Rotate the part on the Y-axis continuously
		summonModel:PivotTo(summonModel:GetPivot() * CFrame.Angles(0, math.rad(1.5 * dt), 0)) 
	end)

end)

GameService.GameStarted:Connect(function()
	
	CurrentWave.Visible = true
	--MergeButton.Visible = true
	
	CurWaveShadow.Visible = true
	MoneyFrame.Visible = true
	TowerSelect.Visible = true
	Time.Visible = true
	
	Health.Bar.Size = UDim2.new(1,0,1,0)
	Health.Visible = true
	OpenUpgrade.Visible = true

	
	popTween(0.25, CurrentWave)
	popTween(0.25, MoneyFrame)
	popTween(0.25, CurWaveShadow)
	popTween(0.25, TowerSelect)
	popTween(0.25, Time)
	popTween(0.25, Health)
	popTween(0.25, OpenUpgrade)
	
	StartTime = os.clock()
end)

onHoverButton(MergeButton)
onHoverButton(TowerSelect.Summon)
onHoverButton(TowerSelect.Reroll)

onHoverButton(Upgrade.Frame.Common.Button)
onHoverButton(Upgrade.Frame.Rare.Button)
onHoverButton(Upgrade.Frame.Legendary.Button)
onHoverButton(Upgrade.Frame.Luck.Button)

local UpgradeOpen = false

OpenUpgrade.MouseButton1Click:Connect(function()
	if UpgradeOpen then return end
	UpgradeOpen = true
	
	slideToPos(Upgrade, UpgradePosition)
	
end)

Upgrade.Close.MouseButton1Click:Connect(function()
	if not UpgradeOpen then return end
	UpgradeOpen = false
	
	slideToPos(Upgrade, UDim2.new(0.5, 0, 1.5, 0))
end)


Values.HP:GetPropertyChangedSignal("Value"):Connect(function()

	local maxHP = Values.MaxHP.Value

	local hp = Values.HP.Value

	local percent = math.clamp(hp/maxHP, 0, 1)

	
	Health.Bar.Size = UDim2.new(percent, 0, 1, 0)
	popTween(0.15, Health)
end)


local function formatTime(totalSeconds)
	local minutes = math.floor(totalSeconds / 60)
	local remainingSeconds = math.floor(totalSeconds % 60)

	return string.format("%02d:%02d", minutes, remainingSeconds)
end

local UpgradeFrame = Upgrade.Frame

UpgradeFrame.Common.Button.MouseButton1Click:Connect(function()
	GameService:Upgrade("TowerUpgrade", {"Common", "Uncommon"}):catch(warn)
	
	--print(success)
end)

UpgradeFrame.Rare.Button.MouseButton1Click:Connect(function()
	GameService:Upgrade("TowerUpgrade", {"Rare", "Epic"}):catch(warn)
end)

--update clock
while task.wait(1) do
	
	local seconds = os.clock() - StartTime -- or any number of seconds
	
	Time.Label.Text = formatTime(seconds)
	
end
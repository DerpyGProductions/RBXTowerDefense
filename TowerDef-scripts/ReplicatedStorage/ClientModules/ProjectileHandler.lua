--[[
    ProjectileHandler (ModuleScript)
    Path: ReplicatedStorage → ClientModules
    Parent: ClientModules
    Exported: 2026-09-29 15:57:27
]]
local TweenService = game:GetService("TweenService")

local ProjectileHandler = {}

local LightningTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
local LightningTweenInfo2 = TweenInfo.new(0.5, Enum.EasingStyle.Linear)

function ProjectileHandler:SingleProjectile(towerModel, targetModel)
	local firePoint = towerModel:FindFirstChild("FirePoint", true) or towerModel.PrimaryPart
	local targetPoint = targetModel.PrimaryPart

	if not firePoint or not targetPoint then return end

	-- Example: Projectile Visual
	local projectile = Instance.new("Part")
	projectile.Size = Vector3.new(0.5, 0.5, 0.5)
	projectile.BrickColor = BrickColor.new("Bright yellow")
	projectile.Anchored = true
	projectile.CanCollide = false
	projectile.CFrame = firePoint.CFrame
	projectile.Parent = workspace.CurrentCamera -- Render inside Camera folder for lower overhead

	local tween = TweenService:Create(projectile, TweenInfo.new(0.15, Enum.EasingStyle.Linear), {
		CFrame = targetPoint.CFrame
	})
	
	task.spawn(function()
		tween:Play()
		tween.Completed:Wait()
		projectile:Destroy()
	end)
end


function ProjectileHandler:ChainLightningProjectile(towerModel, targets)
	
	local lightning = workspace.lightning
	
	--local firePoint = towerModel:FindFirstChild("FirePoint", true) or towerModel.PrimaryPart
	
	for _, target in pairs(targets) do
		
		task.spawn(function()
			
			--print(target)
			
			local targetModel = workspace.ClientEnemies:FindFirstChild("Enemy_" .. target.enemyId)
			if not targetModel then return end
			
			local chainLightning = lightning:Clone()

			chainLightning.Parent = workspace.CurrentCamera
			chainLightning:PivotTo(targetModel:GetPivot()) 

			local tween1 = TweenService:Create(chainLightning.Union, LightningTweenInfo, {Transparency = 0})
			local tween2 = TweenService:Create(chainLightning.Union, LightningTweenInfo2, {Transparency = 1})
			
			chainLightning.Union.Rotation = Vector3.new(math.random(-180, 180), math.random(-180, 180), math.random(-180, 180))
			
			tween1:Play()
			tween1.Completed:Wait()
			tween2:Play()
			tween2.Completed:Wait()
			
			chainLightning:Destroy()
		end)
		
		task.wait()
	end
	
end


return ProjectileHandler

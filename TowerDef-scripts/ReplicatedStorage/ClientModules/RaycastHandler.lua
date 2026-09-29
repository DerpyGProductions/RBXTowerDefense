--[[
    RaycastHandler (ModuleScript)
    Path: ReplicatedStorage → ClientModules
    Parent: ClientModules
    Exported: 2026-09-29 15:57:27
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local RaycastHandler = {}

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include
raycastParams.FilterDescendantsInstances = {}

local MAX_DISTANCE = 500
local lastMousePos = Vector2.new()

local previousHit = nil

function RaycastHandler:UpdateMouseRaycast()
	local mousePos = Vector2.new(mouse.X, mouse.Y)

	-- Skip calculation if the mouse didn't move
	--if mousePos == lastMousePos then return previousHit end
	lastMousePos = mousePos

	-- Generate ray from camera viewport
	local unitRay = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
	local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * MAX_DISTANCE, raycastParams)

	if raycastResult then
		local hitInstance = raycastResult.Instance
		local hitPosition = raycastResult.Position
		local hitNormal = raycastResult.Normal
		
		previousHit = hitInstance
		return hitInstance, hitPosition, hitNormal

		-- Handle your logic here (e.g., updating a placement preview)
		-- print("Hovering over:", hitInstance.Name)
	end
end

function RaycastHandler:SetRaycastInstances(instances)
	raycastParams.FilterDescendantsInstances = instances
end


return RaycastHandler

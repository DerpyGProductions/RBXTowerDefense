--[[
    BuffHandler (Old) (ModuleScript)
    Path: ServerStorage
    Parent: ServerStorage
    Exported: 2026-09-29 15:57:28
]]
local ServerStorage = game:GetService("ServerStorage")

local Events = ServerStorage:WaitForChild("Events")
local Configs = ServerStorage:WaitForChild("Configs")

local AddBuffEvent = Events:WaitForChild("AddBuff")

local Buffs = require(Configs:WaitForChild("Buffs"))

local TowerHandler = require(script.Parent:WaitForChild("TowerHandler"))
local EnemyHandler = require(script.Parent:WaitForChild("EnemyManager"))

local BuffHandler = {}

BuffHandler.Entities = {}
BuffHandler.ActiveBuffs = {}

local function generateBuffID()
		
	local id
	while true do
		id = "Buff_" .. math.random(1000, 9999)
		if not BuffHandler.ActiveBuffs[id] then break end
	end
	
	return id
	
end


function BuffHandler:AddBuff(buffData, target, stacks)
	
	--Target Type: Entity (specific enemy / tower)
	--			   Player (player towers)
	--			   Global (all player towers)
	
	local id = generateBuffID()
	
	local BuffInstance = {
		ID = id,
		Type = buffData.Name,
		
		TargetType = target.TargetType,
		Target = target.Target,

		Stacks = stacks,
		
		Duration = buffData.Duration,
		ExpireTime = buffData.Duration > 0 and os.clock() + buffData.Duration or -1
	
	}
	
	task.spawn(function()
		
		task.wait(BuffInstance.Duration)
	end)
	
	BuffHandler.ActiveBuffs[id] = BuffInstance
	
	
	return BuffInstance

end


function BuffHandler:RemoveBuff(buffID)
	
	if not BuffHandler.ActiveBuffs[buffID] then return end
	
	BuffHandler.ActiveBuffs[buffID] = nil
	
	BuffHandler:RecalculateBuffs()
end

local function getBuffStacks(Modifiers)
	local stacks = {}
	
	for modifier, values in pairs(Modifiers) do
		
		if not stacks[modifier] then
		stacks[modifier] = 
	end
	
end

function BuffHandler:RecalculateBuffs()
	
	local StatStacks = {}
	
	for buffID, buff in pairs(BuffHandler.ActiveBuffs) do
		
		
		if buff.TargetType == "Tower" then
			local targetEntity = TowerHandler:GetTower(buff.Target)
			StatStacks[buff.Target] = 
			
		end
		
	end
	
end

--function BuffHandler:RegisterEntity(entity)
	
--	if not BuffHandler.E
	
--end

function BuffHandler:Start()
	
	AddBuffEvent.OnInvoke = function(buff, target, stacks)
		
		local buffData
		if type(buff) == "string" then --buff name
			buffData = Buffs[buff]
			if not buffData then warn("Buff does not exist") return end
		else
			buffData = buff --custom buff data
		end
		
		
		return BuffHandler:AddBuff(buffData, target, stacks)
	end
	
end


return BuffHandler
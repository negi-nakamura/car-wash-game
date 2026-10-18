local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local PlotConfig = require(script.Parent.Parent.PlotConfig)

local PlotSpawnAllocator = {}

local TemporaryPlotTemplate = ServerStorage:WaitForChild("Assets"):WaitForChild("Plots"):WaitForChild(PlotConfig.TemporaryPlotName)
local PlotsFolder = Workspace:WaitForChild(PlotConfig.PlotsFolderName)
local TemporaryPlots: { [BasePart]: Instance } = {}

local function HideSpawn(spawn: BasePart)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Anchored = true
end

local function ShowTemporaryPlot(spawn: BasePart)
	if TemporaryPlots[spawn] then
		return
	end

	local temporaryPlot = TemporaryPlotTemplate:Clone()
	temporaryPlot.Name = `{spawn.Name} {PlotConfig.TemporaryPlotName}`
	local rotation = spawn:GetAttribute(PlotConfig.RotationAttribute) or 0
	local totalRotation = rotation + PlotConfig.TemporaryPlotRotationOffset
	temporaryPlot:PivotTo(spawn.CFrame * CFrame.Angles(0, math.rad(totalRotation), 0))
	temporaryPlot.Parent = PlotsFolder
	TemporaryPlots[spawn] = temporaryPlot
end

local function HideTemporaryPlot(spawn: BasePart)
	local temporaryPlot = TemporaryPlots[spawn]
	if not temporaryPlot then
		return
	end

	TemporaryPlots[spawn] = nil
	temporaryPlot:Destroy()
end

local function IsAvailable(spawn: BasePart): boolean
	return spawn:GetAttribute(PlotConfig.OccupiedAttribute) ~= true
end

function PlotSpawnAllocator.Claim(player: Player): BasePart?
	local spawns = CollectionService:GetTagged(PlotConfig.SpawnTag)
	
	table.sort(spawns, function(a, b)
		return a:GetAttribute(PlotConfig.IndexAttribute) < b:GetAttribute(PlotConfig.IndexAttribute)
	end)

	for _, instance: BasePart in spawns do
		if not IsAvailable(instance) then
			continue
		end

		instance:SetAttribute(PlotConfig.OccupiedAttribute, true)
		instance:SetAttribute(PlotConfig.OwnerAttributeId, player.UserId)
		instance:SetAttribute(PlotConfig.OwnerAttributeName, player.Name)
		HideTemporaryPlot(instance)
		HideSpawn(instance)
		return instance
	end

	return nil
end

function PlotSpawnAllocator.Release(spawn: BasePart)
	spawn:SetAttribute(PlotConfig.OccupiedAttribute, false)
	spawn:SetAttribute(PlotConfig.OwnerAttributeId, nil)
	spawn:SetAttribute(PlotConfig.OwnerAttributeName, nil)
	ShowTemporaryPlot(spawn)
	HideSpawn(spawn)
end

function PlotSpawnAllocator.Init()
	for _, spawn: BasePart in CollectionService:GetTagged(PlotConfig.SpawnTag) do
		if spawn:GetAttribute(PlotConfig.OccupiedAttribute) == true then
			HideTemporaryPlot(spawn)
		else
			ShowTemporaryPlot(spawn)
		end
		HideSpawn(spawn)
	end
end

return PlotSpawnAllocator
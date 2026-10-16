local CollectionService = game:GetService("CollectionService")
local PlotConfig = require(script.Parent.Parent.PlotConfig)

local PlotSpawnAllocator = {}

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
		instance.Transparency = 1
		instance.CanCollide = false
		instance.Anchored = true
		return instance
	end

	return nil
end

function PlotSpawnAllocator.Release(spawn: BasePart)
	spawn:SetAttribute(PlotConfig.OccupiedAttribute, false)
	spawn:SetAttribute(PlotConfig.OwnerAttributeId, nil)
	spawn:SetAttribute(PlotConfig.OwnerAttributeName, nil)
end

return PlotSpawnAllocator
local ServerStorage = game:GetService("ServerStorage")

local BuildingConfig = require(script.Parent.Parent.BuildingConfig)

local BuildingTemplates = ServerStorage:WaitForChild("Assets"):WaitForChild(BuildingConfig.BuildingTemplatesFolderName)

local BuildingBuilder = {}

function BuildingBuilder.Build(plotModel: Model, buildingName: string): Model
	local spawns = plotModel:FindFirstChild(BuildingConfig.BuildingSpawnsFolderName) :: Folder
	local spawn = spawns:FindFirstChild(buildingName) :: BasePart
	local buildingsFolder = plotModel:FindFirstChild(BuildingConfig.PlotBuildingsFolderName) :: Folder

	spawn.Transparency = 1

	local model = (BuildingTemplates:FindFirstChild(buildingName) :: Model):Clone()

	local boxCFrame, boxSize = model:GetBoundingBox()
	local pivotToBottom = model:GetPivot():ToObjectSpace(boxCFrame).Y - boxSize.Y / 2

	model:PivotTo(spawn.CFrame * CFrame.new(0, spawn.Size.Y / 2 - pivotToBottom, 0))
	model.Parent = buildingsFolder

	return model
end

return BuildingBuilder
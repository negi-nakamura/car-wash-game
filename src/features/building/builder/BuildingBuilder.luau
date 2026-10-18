local ServerStorage = game:GetService("ServerStorage")

local BuildingConfig = require(script.Parent.Parent.BuildingConfig)

local BuildingTemplates = ServerStorage:WaitForChild("Assets"):WaitForChild(BuildingConfig.BuildingTemplatesFolderName)

local BuildingBuilder = {}

local function GetLowestY(model: Model, pointsFolder: Instance?): number
	local lowestY = math.huge

	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") or (pointsFolder and part:IsDescendantOf(pointsFolder)) then
			continue
		end

		local cframe, size = part.CFrame, part.Size
		local halfHeight = (
			math.abs(cframe.RightVector.Y) * size.X
			+ math.abs(cframe.UpVector.Y) * size.Y
			+ math.abs(cframe.LookVector.Y) * size.Z
		) / 2

		lowestY = math.min(lowestY, cframe.Position.Y - halfHeight)
	end

	return lowestY
end

function BuildingBuilder.Build(plotModel: Model, buildingName: string): Model
	local spawns = plotModel:FindFirstChild(BuildingConfig.BuildingSpawnsFolderName) :: Folder
	local spawn = spawns:FindFirstChild(buildingName) :: BasePart
	local buildingsFolder = plotModel:FindFirstChild(BuildingConfig.PlotBuildingsFolderName) :: Folder

	spawn.Transparency = 1

	local model = (BuildingTemplates:FindFirstChild(buildingName) :: Model):Clone()

	local pointsFolder = model:FindFirstChild(BuildingConfig.PointsFolderName)
	local pivotToBottom = GetLowestY(model, pointsFolder) - model:GetPivot().Position.Y

	model:PivotTo(spawn.CFrame * CFrame.new(0, spawn.Size.Y / 2 - pivotToBottom, 0))
	model.Parent = buildingsFolder

	return model
end

return BuildingBuilder

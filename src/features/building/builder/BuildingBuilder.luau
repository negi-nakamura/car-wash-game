local ServerStorage = game:GetService("ServerStorage")

local BuildingConfig = require(script.Parent.Parent.BuildingConfig)

local BuildingTemplates = ServerStorage:WaitForChild("Assets"):WaitForChild(BuildingConfig.BuildingTemplatesFolderName)

local BuildingBuilder = {}

local function IsPointPart(part: BasePart, model: Model): boolean
	local ancestor = part.Parent
	while ancestor and ancestor ~= model do
		if ancestor.Name == BuildingConfig.PointsFolderName then
			return true
		end
		ancestor = ancestor.Parent
	end

	return false
end

local function GetLowestY(model: Model): number
	local lowestY = math.huge

	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") or IsPointPart(part, model) then
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

	local pivotToBottom = GetLowestY(model) - model:GetPivot().Position.Y

	model:PivotTo(spawn.CFrame * CFrame.new(0, spawn.Size.Y / 2 - pivotToBottom, 0))
	model.Parent = buildingsFolder

	return model
end

return BuildingBuilder

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local PlotConfig = require(script.Parent.Parent.PlotConfig)

local PlotTemplate = ServerStorage:WaitForChild("Assets"):WaitForChild("Plots"):WaitForChild("Plot")
local PlotsFolder = Workspace:WaitForChild(PlotConfig.PlotsFolderName)

local PlotBuilder = {}

function PlotBuilder.Build(plotSpawn: BasePart, player: Player): (Model, BasePart)
	local model = PlotTemplate:Clone()
	model.Name = PlotConfig.ModelNameFormat:format(player.Name)
	model:SetAttribute(PlotConfig.OwnerAttributeId, player.UserId)
	model:SetAttribute(PlotConfig.OwnerAttributeName, player.Name)

	local rotation = plotSpawn:GetAttribute(PlotConfig.RotationAttribute) or 0
	model:PivotTo(plotSpawn.CFrame * CFrame.Angles(0, math.rad(rotation), 0))

	local playerSpawn = model:FindFirstChild(PlotConfig.PlayerSpawnName, true) :: BasePart?

	if playerSpawn then
		playerSpawn.Transparency = 1
	else
		warn(`[PlotBuilder] {model.Name} has no "{PlotConfig.PlayerSpawnName}" part, using the plot spawn`)
	end

	model.Parent = PlotsFolder
	return model, playerSpawn or plotSpawn
end

return PlotBuilder
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local PlotConfig = require(script.Parent.Parent.PlotConfig)

local PlotTemplate = ServerStorage:WaitForChild("Assets"):WaitForChild("Plots"):WaitForChild("Plot")
local PlotsFolder = Workspace:WaitForChild(PlotConfig.PlotsFolderName)

local PlotBuilder = {}

function PlotBuilder.Build(plotSpawn: BasePart, player: Player): Model
	local model = PlotTemplate:Clone()
	model.Name = PlotConfig.ModelNameFormat:format(player.Name)
	model:SetAttribute(PlotConfig.OwnerAttributeId, player.UserId)
	model:SetAttribute(PlotConfig.OwnerAttributeName, player.Name)
	model:PivotTo(plotSpawn.CFrame)
	model.Parent = PlotsFolder
	return model
end

return PlotBuilder
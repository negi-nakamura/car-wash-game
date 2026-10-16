local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerState = require(ServerScriptService.server.core.PlayerState)
local PlotService = require(script.Parent.features.plot.PlotService)

Players.PlayerAdded:Connect(PlayerState.Init)

for _, player in Players:GetPlayers() do
	PlayerState.Init(player)
end

PlotService.Init()
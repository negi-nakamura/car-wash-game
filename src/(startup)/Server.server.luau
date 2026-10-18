local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerState = require(ServerScriptService.server.core.PlayerState)
local BuildingService = require(script.Parent.features.building.BuildingService)
local PlotService = require(script.Parent.features.plot.PlotService)
local CustomerService = require(script.Parent.features.customer.CustomerService)
local CashierService = require(script.Parent.features.cashier.CashierService)

Players.PlayerAdded:Connect(PlayerState.Init)
for _, player in Players:GetPlayers() do
	PlayerState.Init(player)
end


BuildingService.Init()
CustomerService.Init()
CashierService.Init()
PlotService.Init()
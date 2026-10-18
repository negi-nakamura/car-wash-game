local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerState = require(ServerScriptService.server.core.PlayerState)
local BuildingService = require(script.Parent.features.building.BuildingService)
local BillboardService = require(script.Parent.features.building.BillboardService)
local PlotService = require(script.Parent.features.plot.PlotService)
local CustomerService = require(script.Parent.features.customer.CustomerService)
local CashierService = require(script.Parent.features.cashier.CashierService)
local EnvironmentService = require(ServerScriptService.server.features.environment.EnvironmentService)
local NpcService = require(ServerScriptService.server.features.npc.NpcService)
local CarWashService = require(ServerScriptService.server.features.carwash.CarWashService)

Players.PlayerAdded:Connect(PlayerState.Init)
for _, player in Players:GetPlayers() do
	PlayerState.Init(player)
end

BuildingService.Init()
BillboardService.Init()
CustomerService.Init()
CashierService.Init()
PlotService.Init()
EnvironmentService.Init()
NpcService.Init()
CarWashService.Init()
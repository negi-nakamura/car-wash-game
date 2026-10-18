local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlotService = require(ServerScriptService.server.features.plot.PlotService)
local Plot = require(ServerScriptService.server.features.plot.class.Plot)
local Signal = require(ReplicatedStorage.Packages.signal)
local Building = require(script.Parent.class.Building)
local BuildingConfig = require(script.Parent.BuildingConfig)

local BuildingService = {}

local BuildingsByPlot: { [Plot.Plot]: { [string]: Building.Building } } = {}

BuildingService.BuildingAdded = Signal.new()

function BuildingService.Build(plot: Plot.Plot, name: string): Building.Building
	local buildings = BuildingsByPlot[plot]

	if not buildings then
		buildings = {}
		BuildingsByPlot[plot] = buildings
		plot.Janitor:Add(function()
			BuildingsByPlot[plot] = nil
		end)
	end

	local building = Building.New(plot, name)
	buildings[name] = building
	plot.Janitor:Add(building, "Destroy")

	BuildingService.BuildingAdded:Fire(building)

	return building
end

function BuildingService.Get(plot: Plot.Plot, name: string): Building.Building?
	local buildings = BuildingsByPlot[plot]
	return buildings and buildings[name]
end

function BuildingService.Init()
	PlotService.PlotAdded:Connect(function(plot)
		for _, name in BuildingConfig.StarterBuildings do
			BuildingService.Build(plot, name)
		end
	end)
end

return BuildingService
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Plot = require(ServerScriptService.server.features.plot.class.Plot)
local Janitor = require(ReplicatedStorage.Packages.janitor)
local BuildingBuilder = require(script.Parent.Parent.builder.BuildingBuilder)

local Building = {}
Building.__index = Building

export type Building = typeof(setmetatable(
	{} :: {
		Name: string,
		Plot: Plot.Plot,
		Model: Model,
		Janitor: typeof(Janitor.new()),
	},
	Building
))

function Building.New(plot: Plot.Plot, name: string): Building
	local self = setmetatable({
		Name = name,
		Plot = plot,
		Model = BuildingBuilder.Build(plot.Model, name),
		Janitor = Janitor.new(),
	}, Building)

	self.Janitor:Add(self.Model, "Destroy")

	return self
end

function Building:Destroy()
	self.Janitor:Destroy()
end

return Building
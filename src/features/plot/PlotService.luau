local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.signal)
local Plot = require(script.Parent.class.Plot)

local PlotService = {}

local PlotByPlayer: { [Player]: Plot.Plot } = {}

PlotService.PlotAdded = Signal.new()

local function AssignPlot(player: Player)
	if PlotByPlayer[player] then
		return
	end

	local plot = Plot.New(player)
	if not plot then
		warn(`[PlotService] No free plot for {player.Name}`)
		return
	end

	PlotByPlayer[player] = plot
	PlotService.PlotAdded:Fire(plot)
end

local function ReleasePlot(player: Player)
	local plot = PlotByPlayer[player]
	if not plot then
		return
	end

	PlotByPlayer[player] = nil
	plot:Destroy()
end

function PlotService.GetPlot(player: Player): Plot.Plot?
	return PlotByPlayer[player]
end

function PlotService.Init()
	Players.PlayerAdded:Connect(AssignPlot)
	Players.PlayerRemoving:Connect(ReleasePlot)

	for _, player in Players:GetPlayers() do
		AssignPlot(player)
	end
end

return PlotService
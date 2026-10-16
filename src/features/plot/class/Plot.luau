local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Janitor = require(ReplicatedStorage.Packages.janitor)
local PlotBuilder = require(script.Parent.Parent.builder.PlotBuilder)
local PlotConfig = require(script.Parent.Parent.PlotConfig)
local PlotSpawnAllocator = require(script.Parent.Parent.modules.PlotSpawnAllocator)

local Plot = {}
Plot.__index = Plot

export type Plot = typeof(setmetatable(
	{} :: {
		Owner: Player?,
		Spawn: BasePart,
		Model: Model,
		PlayerSpawn: BasePart,
		_janitor: typeof(Janitor.new()),
	},
	Plot
))

function Plot.New(player: Player): Plot?
	local spawn = PlotSpawnAllocator.Claim(player)

	if not spawn then
		return nil
	end

	local model, playerSpawn = PlotBuilder.Build(spawn, player)

	local self = setmetatable({
		Owner = player :: Player?,
		Spawn = spawn,
		Model = model,
		PlayerSpawn = playerSpawn,
		_janitor = Janitor.new(),
	}, Plot)

	self._janitor:Add(self.Model, "Destroy")

	self._janitor:Add(player.CharacterAdded:Connect(function(character: Model)
		self:_Teleport(character)
	end), "Disconnect")

	if player.Character then
		task.spawn(self._Teleport, self, player.Character)
	end

	return self
end

function Plot:Destroy()
	self.Owner = nil
	self._janitor:Destroy()
	PlotSpawnAllocator.Release(self.Spawn)
end

function Plot:_Teleport(character: Model)
	local rootPart = character:WaitForChild("HumanoidRootPart", PlotConfig.CharacterWaitSeconds)

	if not rootPart or not self.Owner then
		return
	end

	local heightOffset = self.PlayerSpawn.Size.Y / 2 + PlotConfig.TeleportHeightOffset
	character:PivotTo(self.PlayerSpawn.CFrame + Vector3.new(0, heightOffset, 0))
end

return Plot
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local BuildingService = require(ServerScriptService.server.features.building.BuildingService)
local Plot = require(ServerScriptService.server.features.plot.class.Plot)
local CustomerConfig = require(script.Parent.Parent.CustomerConfig)

local Highway = Workspace:WaitForChild(CustomerConfig.HighwayFolderName)

local CustomerPath = {}

export type RouteEntry = { Building: string?, Point: string, Part: BasePart?, Stop: boolean?, Trigger: boolean? }
export type Point = { Name: string, Position: Vector3, Stop: boolean, Trigger: boolean }

-- Middle of a point part's top face: the car's bottom rests on it, like a building on its spawn part
local function GetSurfacePosition(part: BasePart): Vector3
	return part.CFrame:PointToWorldSpace(Vector3.new(0, part.Size.Y / 2, 0))
end

local function GetHighwayPosition(part: BasePart): Vector3
	return part:GetPivot().Position
end

function CustomerPath.GetLane(plot: Plot.Plot, laneOverride: number?): number
	if laneOverride then
		assert(laneOverride >= 1 and laneOverride <= CustomerConfig.HighwayLaneCount, `Highway lane {laneOverride} is outside the configured lane count`)
		return laneOverride
	end

	local start = Highway:WaitForChild(CustomerConfig.HighwayStartName .. CustomerConfig.HighwayLeftLane) :: BasePart
	local finish = Highway:WaitForChild(CustomerConfig.HighwayEndName .. CustomerConfig.HighwayLeftLane) :: BasePart
	local highwayCenterZ = (start.Position.Z + finish.Position.Z) / 2

	if plot.Spawn.Position.Z <= highwayCenterZ then
		return CustomerConfig.HighwayRightLane
	end

	return CustomerConfig.HighwayLeftLane
end

local function GetLanePointName(lane: number, isStart: boolean): string
	local pointName = if isStart then CustomerConfig.HighwayStartName else CustomerConfig.HighwayEndName
	return pointName .. lane
end

local function GetHighwayPart(plot: Plot.Plot, pointName: string, laneOverride: number?): BasePart
	local lane = CustomerPath.GetLane(plot, laneOverride)
	local laneName

	if pointName == CustomerConfig.HighwayStartName then
		laneName = GetLanePointName(lane, true)
	elseif pointName == CustomerConfig.HighwayEndName then
		laneName = GetLanePointName(lane, false)
	else
		laneName = pointName .. lane
	end

	local part = Highway:FindFirstChild(laneName)
	assert(part and part:IsA("BasePart"), `Workspace.{CustomerConfig.HighwayFolderName}.{laneName} is missing`)
	return part
end

-- Highway entries come from Workspace.Highway, building entries from inside the plot's building model
local function FindPointPart(plot: Plot.Plot, entry: RouteEntry): BasePart
	if entry.Part then
		return entry.Part
	end

	if not entry.Building then
		return GetHighwayPart(plot, entry.Point)
	end

	local building = BuildingService.Get(plot, entry.Building)
	assert(building, `Building "{entry.Building}" is not built on "{plot.Model.Name}"`)

	local part = building.Model:FindFirstChild(entry.Point, true)
	assert(part and part:IsA("BasePart"), `Building "{entry.Building}" has no point part "{entry.Point}"`)
	return part
end

-- Frame on top of the plot's highway lane, level and facing its matching exit lane
function CustomerPath.GetSpawnFrame(plot: Plot.Plot, laneOverride: number?): CFrame
	local lane = CustomerPath.GetLane(plot, laneOverride)
	local start = GetHighwayPosition(Highway:WaitForChild(GetLanePointName(lane, true)) :: BasePart)
	local finish = GetHighwayPosition(Highway:WaitForChild(GetLanePointName(lane, false)) :: BasePart)

	return CFrame.lookAt(start, Vector3.new(finish.X, start.Y, finish.Z))
end

function CustomerPath.Resolve(plot: Plot.Plot, route: { RouteEntry }, laneOverride: number?): { Point }
	local points = {}

	for _, entry in route do
		local part = if entry.Building then FindPointPart(plot, entry) else GetHighwayPart(plot, entry.Point, laneOverride)
		local position = if entry.Building then GetSurfacePosition(part) else GetHighwayPosition(part)

		table.insert(points, {
			Name = entry.Point,
			Position = position,
			Stop = entry.Stop == true,
				Trigger = entry.Trigger == true,
		})
	end

	return points
end

return CustomerPath
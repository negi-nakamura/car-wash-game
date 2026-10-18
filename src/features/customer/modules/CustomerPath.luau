local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local BuildingService = require(ServerScriptService.server.features.building.BuildingService)
local Plot = require(ServerScriptService.server.features.plot.class.Plot)
local CustomerConfig = require(script.Parent.Parent.CustomerConfig)

local Highway = Workspace:WaitForChild(CustomerConfig.HighwayFolderName)
local HighwayStart = Highway:WaitForChild(CustomerConfig.HighwayStartName)
local HighwayEnd = Highway:WaitForChild(CustomerConfig.HighwayEndName)

local CustomerPath = {}

export type RouteEntry = { Building: string?, Point: string, Stop: boolean? }
export type Point = { Name: string, Position: Vector3, Stop: boolean }

-- Middle of a point part's top face: the car's bottom rests on it, like a building on its spawn part
local function GetSurfacePosition(part: BasePart): Vector3
	return part.CFrame:PointToWorldSpace(Vector3.new(0, part.Size.Y / 2, 0))
end

-- Highway entries come from Workspace.Highway, building entries from inside the plot's building model
local function FindPointPart(plot: Plot.Plot, entry: RouteEntry): BasePart
	if not entry.Building then
		local part = Highway:FindFirstChild(entry.Point)
		assert(part and part:IsA("BasePart"), `Workspace.{CustomerConfig.HighwayFolderName}.{entry.Point} is missing`)
		return part
	end

	local building = BuildingService.Get(plot, entry.Building)
	assert(building, `Building "{entry.Building}" is not built on "{plot.Model.Name}"`)

	local part = building.Model:FindFirstChild(entry.Point, true)
	assert(part and part:IsA("BasePart"), `Building "{entry.Building}" has no point part "{entry.Point}"`)
	return part
end

-- Frame on top of Highway Start, level and facing Highway End
function CustomerPath.GetSpawnFrame(): CFrame
	local start = GetSurfacePosition(HighwayStart)
	local finish = GetSurfacePosition(HighwayEnd)

	return CFrame.lookAt(start, Vector3.new(finish.X, start.Y, finish.Z))
end

function CustomerPath.Resolve(plot: Plot.Plot, route: { RouteEntry }): { Point }
	local points = {}

	for _, entry in route do
		table.insert(points, {
			Name = entry.Point,
			Position = GetSurfacePosition(FindPointPart(plot, entry)),
			Stop = entry.Stop == true,
		})
	end

	return points
end

return CustomerPath
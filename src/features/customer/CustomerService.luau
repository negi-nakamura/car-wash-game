local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BuildingService = require(ServerScriptService.server.features.building.BuildingService)
local EnvironmentService = require(ServerScriptService.server.features.environment.EnvironmentService)
local Plot = require(ServerScriptService.server.features.plot.class.Plot)
local Signal = require(ReplicatedStorage.Packages.signal)
local Customer = require(script.Parent.class.Customer)
local CustomerQueue = require(script.Parent.class.CustomerQueue)
local CustomerConfig = require(script.Parent.CustomerConfig)
local CustomerPath = require(script.Parent.modules.CustomerPath)

local CustomerService = {}

local Random = Random.new()

type PlotCustomers = {
	Queue: CustomerQueue.CustomerQueue,
	Customers: { [Customer.Customer]: true },
	SpawnPending: boolean, -- true while a spawn is waiting on its delay
	QueueClosing: boolean, -- true while customers from the previous day are leaving
}

local CustomersByPlot: { [Plot.Plot]: PlotCustomers } = {}
local NextSpawnAtByLane: { [number]: number } = {}
local AmbientCustomers: { [Customer.Customer]: true } = {}
local AmbientSpawnPendingByLane: { [number]: boolean } = {}
local NextAmbientSpawnAtByLane: { [number]: number } = {}
local ScheduleSpawn

function CustomerService.GetFrontCustomer(plot: Plot.Plot): Customer.Customer?
	local state = CustomersByPlot[plot]
	return state and state.Queue:GetFront() or nil
end

function CustomerService.RemoveFromQueue(plot: Plot.Plot, customer: Customer.Customer)
	local state = CustomersByPlot[plot]
	if state then
		state.Queue:Remove(customer)
		if not state.Queue:IsFull() then
			ScheduleSpawn(plot, state)
		end
	end
end

-- Fires (customer, pointName) when a customer's car parks at a stop point
CustomerService.CustomerStopped = Signal.new()

-- True once every building the customer route needs is built on the plot
local function IsReady(plot: Plot.Plot): boolean
	for _, name in CustomerConfig.RequiredBuildings do
		if not BuildingService.Get(plot, name) then
			return false
		end
	end

	return true
end

local function IsShopOpen(): boolean
	return EnvironmentService.IsOpen()
end

local function CloseQueue(state: PlotCustomers)
	state.QueueClosing = true
	local customers = {}
	for _, customer in state.Queue:GetCustomers() do
		table.insert(customers, {
			Customer = customer,
			Parked = state.Queue:IsParked(customer),
		})
	end

	-- Cars that have not reached a queue point will leave from the highway route
	-- and will never pass CashierExitCheck, so remove them from the queue now.
	for _, entry in customers do
		if not entry.Parked then
			state.Queue:Remove(entry.Customer)
		end
	end

	for _, entry in customers do
		local customer = entry.Customer
		if not customer.Destroyed then
			customer:StopWaiting()

			local route = if entry.Parked
				then CustomerConfig.RejectRoute
				else { { Point = CustomerConfig.HighwayEndName } }
			customer:Follow(route)
		end
	end
end

local function TryResumeQueue(plot: Plot.Plot, state: PlotCustomers)
	if not IsShopOpen() then
		return
	end

	if state.QueueClosing then
		if not state.Queue:IsEmpty() then
			return
		end
		state.QueueClosing = false
	end

	if not state.Queue:IsFull() then
		ScheduleSpawn(plot, state)
	end
end

local SpawnCustomer
local FillQueue
local ScheduleAmbientSpawn

-- Reserve the next spawn slot on this lane so plots sharing it cannot overlap cars.
ScheduleSpawn = function(plot: Plot.Plot, state: PlotCustomers)
	if state.SpawnPending then
		return
	end

	state.SpawnPending = true
	local lane = CustomerPath.GetLane(plot)
	local now = os.clock()
	local spawnAt = math.max(now, NextSpawnAtByLane[lane] or now)
	NextSpawnAtByLane[lane] = spawnAt + CustomerConfig.HighwaySpawnIntervalSeconds

	task.delay(spawnAt - now, function()
		state.SpawnPending = false

		-- The plot may have been destroyed while waiting
		if CustomersByPlot[plot] == state and IsShopOpen() then
			SpawnCustomer(plot, state)
		end
	end)
end

function SpawnCustomer(plot: Plot.Plot, state: PlotCustomers, scheduleNext: boolean?)
	if not IsShopOpen() or state.Queue:IsFull() then
		return
	end

	local customer = Customer.New(plot)
	state.Customers[customer] = true

	customer.Stopped:Connect(function(pointName: string)
		state.Queue:Parked(customer, pointName)
		CustomerService.CustomerStopped:Fire(customer, pointName)
	end)

	customer.Passed:Connect(function(pointName: string)
		state.Queue:Departed(customer, pointName)

		if pointName == CustomerConfig.LaneExitCheckPoint then
			FillQueue(plot, state)
		end
	end)

	customer.Departed:Connect(function(pointName: string)
		state.Queue:Departed(customer, pointName)
	end)

	-- The route is over (the car reached the highway end)
	customer.Finished:Connect(function()
		state.Customers[customer] = nil
		customer:Destroy()
	end)

	state.Queue:Join(customer)

	-- Keep filling the queue
	if scheduleNext ~= false and not state.Queue:IsFull() then
		ScheduleSpawn(plot, state)
	end
end

local function GetAmbientPlot(): Plot.Plot?
	for plot in CustomersByPlot do
		return plot
	end

	return nil
end

local function SpawnAmbientCustomer(lane: number)
	local plot = GetAmbientPlot()
	if not plot then
		return
	end

	local customer = Customer.New(plot, lane)
	AmbientCustomers[customer] = true

	customer.Finished:Connect(function()
		AmbientCustomers[customer] = nil
		customer:Destroy()
	end)

	customer:Follow({ { Point = CustomerConfig.HighwayEndName } })
end

ScheduleAmbientSpawn = function(lane: number)
	if AmbientSpawnPendingByLane[lane] then
		return
	end

	AmbientSpawnPendingByLane[lane] = true
	local now = os.clock()
	local spawnAt = math.max(now, NextAmbientSpawnAtByLane[lane] or now)
	local interval = Random:NextNumber(
		CustomerConfig.AmbientSpawnMinIntervalSeconds,
		CustomerConfig.AmbientSpawnMaxIntervalSeconds
	)
	NextAmbientSpawnAtByLane[lane] = spawnAt + interval

	task.delay(spawnAt - now, function()
		AmbientSpawnPendingByLane[lane] = false
		SpawnAmbientCustomer(lane)
		ScheduleAmbientSpawn(lane)
	end)
end

function FillQueue(plot: Plot.Plot, state: PlotCustomers)
	if CustomersByPlot[plot] == state then
		TryResumeQueue(plot, state)
	end
end

local function StartCustomers(plot: Plot.Plot)
	local state: PlotCustomers = {
		Queue = CustomerQueue.New(),
		Customers = {},
		SpawnPending = false,
		QueueClosing = false,
	}
	CustomersByPlot[plot] = state

	plot.Janitor:Add(function()
		CustomersByPlot[plot] = nil

		for customer in state.Customers do
			customer:Destroy()
		end
	end)

	ScheduleSpawn(plot, state)
	ScheduleAmbientSpawn(CustomerConfig.AmbientLaneLeft)
	ScheduleAmbientSpawn(CustomerConfig.AmbientLaneRight)
end

function CustomerService.Init()
	BuildingService.BuildingAdded:Connect(function(building)
		local plot = building.Plot

		if not CustomersByPlot[plot] and IsReady(plot) then
			StartCustomers(plot)
		end
	end)

	EnvironmentService.OpenChanged:Connect(function(isOpen: boolean)
		if not isOpen then
			for _, state in CustomersByPlot do
				CloseQueue(state)
			end
			return
		end

		for plot, state in CustomersByPlot do
			TryResumeQueue(plot, state)
		end
	end)
end

return CustomerService

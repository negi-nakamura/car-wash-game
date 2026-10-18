local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BuildingService = require(ServerScriptService.server.features.building.BuildingService)
local Plot = require(ServerScriptService.server.features.plot.class.Plot)
local Signal = require(ReplicatedStorage.Packages.signal)
local Customer = require(script.Parent.class.Customer)
local CustomerQueue = require(script.Parent.class.CustomerQueue)
local CustomerConfig = require(script.Parent.CustomerConfig)

local CustomerService = {}

type PlotCustomers = {
	Queue: CustomerQueue.CustomerQueue,
	Customers: { [Customer.Customer]: true },
	SpawnPending: boolean, -- true while a spawn is waiting on its delay
}

local CustomersByPlot: { [Plot.Plot]: PlotCustomers } = {}

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

local SpawnCustomer

-- Spawn after the delay, unless one is already waiting
local function ScheduleSpawn(plot: Plot.Plot, state: PlotCustomers)
	if state.SpawnPending then
		return
	end

	state.SpawnPending = true

	task.delay(CustomerConfig.NextCustomerDelaySeconds, function()
		state.SpawnPending = false

		-- The plot may have been destroyed while waiting
		if CustomersByPlot[plot] == state then
			SpawnCustomer(plot, state)
		end
	end)
end

function SpawnCustomer(plot: Plot.Plot, state: PlotCustomers)
	if state.Queue:IsFull() then
		return
	end

	local customer = Customer.New(plot)
	state.Customers[customer] = true

	customer.Stopped:Connect(function(pointName: string)
		state.Queue:Parked(customer, pointName)
		CustomerService.CustomerStopped:Fire(customer, pointName)
	end)

	customer.Departed:Connect(function(pointName: string)
		state.Queue:Departed(customer, pointName)

		-- The front customer left, so the queue has room again
		if pointName == CustomerConfig.LaneExitCheckPoint then
			ScheduleSpawn(plot, state)
		end
	end)

	-- The route is over (the car reached the highway end)
	customer.Finished:Connect(function()
		state.Customers[customer] = nil
		customer:Destroy()
	end)

	state.Queue:Join(customer)

	-- Keep filling the queue
	if not state.Queue:IsFull() then
		ScheduleSpawn(plot, state)
	end
end

local function StartCustomers(plot: Plot.Plot)
	local state: PlotCustomers = {
		Queue = CustomerQueue.New(),
		Customers = {},
		SpawnPending = false,
	}
	CustomersByPlot[plot] = state

	plot.Janitor:Add(function()
		CustomersByPlot[plot] = nil

		for customer in state.Customers do
			customer:Destroy()
		end
	end)

	SpawnCustomer(plot, state)
end

function CustomerService.Init()
	BuildingService.BuildingAdded:Connect(function(building)
		local plot = building.Plot

		if not CustomersByPlot[plot] and IsReady(plot) then
			StartCustomers(plot)
		end
	end)
end

return CustomerService

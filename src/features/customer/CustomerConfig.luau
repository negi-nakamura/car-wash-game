return table.freeze({
	-- ServerStorage.Assets
	CustomerTemplatesFolderName = "Customers", -- holds the car and driver templates
	CarTemplateName = "Car", -- car model with a PrimaryPart and a driver seat
	DriverTemplateName = "Driver", -- rig with a Humanoid
	DriverSeatName = "DriverSeat", -- Seat inside the car, the driver sits here

	-- Workspace
	CustomersFolderName = "Customers", -- spawned cars and drivers are parented here
	HighwayFolderName = "Highway", -- holds the shared highway points
	HighwayStartName = "Start", -- every car spawns here, facing the End point
	HighwayEndName = "End", -- the point cars drive away towards

	-- Movement
	CarSpeed = 30, -- studs per second while driving straight
	TurnSpeed = 90, -- degrees per second while turning in place

	-- Spawning
	RequiredBuildings = { "CashierLane" }, -- customers start once all of these are built on a plot (add "CarWash" when the bays exist)
	NextCustomerDelaySeconds = 2, -- pause before the next customer spawns while the queue has room

	-- Cashier lane
	LaneBuilding = "CashierLane", -- building that holds the lane points
	LaneEntrancePoint = "LaneEntrance", -- where cars turn off the highway into the lane
	QueuePoints = { "CashierStop", "Queue2", "Queue3" }, -- parking points in the lane, the front of the queue first

	-- Routes: Building = building name, Point = part name inside it, Stop = true to wait there.
	-- An entry without Building is a point inside Workspace.Highway.
	RejectRoute = {
		{ Building = "CashierLane", Point = "CashierExit" },
		{ Building = "CashierLane", Point = "RejectRejoin" },
		{ Point = "End" },
	}, -- from the front of the queue back out to Highway End
})

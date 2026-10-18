return table.freeze({
	-- ServerStorage.Assets
	CustomerTemplatesFolderName = "Customers", -- holds the car and driver templates
	CarTemplateName = "Car", -- car model with a PrimaryPart and a driver seat
	DriverTemplateName = "Driver", -- rig with a Humanoid
	DriverSeatName = "DriverSeat", -- Seat inside the car, the driver sits here

	-- Workspace
	CustomersFolderName = "Customers", -- spawned cars and drivers are parented here
	HighwayFolderName = "Highway", -- holds the shared highway points
	HighwayStartName = "Start", -- prefix for the four highway spawn points: Start1 through Start4
	HighwayEndName = "End", -- prefix for the four highway exit points: End1 through End4
	HighwayLaneCount = 4,
	HighwayLeftLane = 1,
	HighwayRightLane = 4,

	-- Movement
	CarSpeed = 40, -- studs per second while driving straight
	TurnSpeed = 90, -- degrees per second while turning in place
	AccelerationSeconds = 0.5, -- seconds used for acceleration
	DecelerationSeconds = 1, -- seconds used for deceleration
	InstantMovementPoints = { CashierExitCheck = true }, -- points reached without acceleration or deceleration

	-- Spawning
	RequiredBuildings = { "CashierLane" }, -- customers start once all of these are built on a plot (add "CarWash" when the bays exist)
	HighwaySpawnIntervalSeconds = 3, -- minimum time between cars sharing a highway lane
	NextCustomerDelaySeconds = 2, -- pause before the next customer spawns while the queue has room
	AmbientLaneLeft = 2,
	AmbientLaneRight = 3,
	AmbientSpawnMinIntervalSeconds = 6,
	AmbientSpawnMaxIntervalSeconds = 10,

	-- Cashier lane
	LaneBuilding = "CashierLane", -- building that holds the lane points
	LaneEntrancePoint = "LaneEntrance", -- where cars turn off the highway into the lane
	LaneExitPoint = "CashierExit", -- where rejected cars leave the queue
	LaneExitCheckPoint = "CashierExitCheck", -- where rejected cars trigger queue advancement
	LaneRejoinPoint = "RejectRejoin", -- where rejected cars finish leaving the queue
	QueuePoints = { "CashierStop", "Queue2", "Queue3" }, -- parking points in the lane, the front of the queue first
	QueueWaitSeconds = 60, -- total time the customer spends waiting in the queue
	DriverNames = {
		"Castro", "Sustitudo", "Alingalan", "Abonite", "Prado", "Dela Cerna",
		"Fagtanac", "Dela Peña", "Baquilar", "Bernal", "Magnaye", "Senillo",
		"Quijano", "Relente", "Belgica", "Cerdan", "Ruina", "Sy",
		"Loreto", "Silvestre", "Genova", "Villafranca", "Gandiongco", "Torrejos",
		"Vicencio", "Partosa", "Ancheta", "Cuadra", "Morcilla", "Bongalbal",
		"Valendiano", "Agustin", "Marquez", "Pacoli", "Relosa", "Villanueva",
		"Balagot", "Villanueva", "Abong", "Belarmino", "Manoguid", "Factor",
		"Laguitan", "Sergote", "Constantino", "Pekitpekit", "Nazi"
	},

	-- Routes: Building = building name, Point = part name inside it, Stop = true to wait there.
	-- An entry without Building is a point inside Workspace.Highway.
	RejectRoute = {
		{ Building = "CashierLane", Point = "CashierExit", Stop = true },
		{ Building = "CashierLane", Point = "CashierExitCheck", Trigger = true },
		{ Building = "CashierLane", Point = "RejectRejoin", Stop = true },
		{ Point = "End" },
	}, -- from the front of the queue back out to Highway End
})

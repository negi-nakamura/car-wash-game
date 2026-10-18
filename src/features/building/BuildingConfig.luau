return table.freeze({
	-- ServerStorage.Assets
	BuildingTemplatesFolderName = "Buildings", -- holds one model per building

	-- Plot template
	BuildingSpawnsFolderName = "BuildingSpawns", -- one part per building, named after the building
	PlotBuildingsFolderName = "Buildings", -- built buildings are parented here

	-- Gameplay
	StarterBuildings = { "CarWash", "Cashier", "Billboard", "CashierLane" }, -- built automatically when a plot is added
})
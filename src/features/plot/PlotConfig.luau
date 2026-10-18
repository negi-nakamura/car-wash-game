return table.freeze({
	-- Workspace
	PlotsFolderName = "Plots", -- Workspace folder that holds the cloned plot models

	-- Spawn parts (A, B, C, D)
	SpawnTag = "PlotSpawn", -- CollectionService tag on every plot spawn part
	OccupiedAttribute = "Occupied", -- boolean attribute on the spawn part; true while a player owns it
	RotationAttribute = "Rotation", -- number attribute on the spawn part: degrees to rotate the plot around Y (default 0)
	IndexAttribute = "Index", -- number attribute on the spawn part: fill order, lowest first

	-- Ownership (set on both the spawn part and the cloned model)
	OwnerAttributeId = "OwnerId", -- owner's UserId (number); nil when the plot is free
	OwnerAttributeName = "OwnerName", -- owner's Name (string); nil when the plot is free

	-- Cloned plot model
	ModelNameFormat = "%s's Plot", -- model name, formatted with the player's name
	TemporaryPlotName = "TemporaryPlot", -- ServerStorage.Assets.Plots asset shown on unclaimed spawns
	TemporaryPlotRotationOffset = 180, -- the temporary asset's buildings are authored backwards
	PlayerSpawnName = "PlayerSpawn", -- name of the part inside the Plot template where the owner spawns,

	-- Teleport
	TeleportHeightOffset = 3, -- studs above the top of the spawn part, so the character doesn't clip into it
	CharacterWaitSeconds = 5, -- max wait for HumanoidRootPart before giving up on a teleport
})
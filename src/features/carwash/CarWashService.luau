local ServerScriptService = game:GetService("ServerScriptService")

local BuildingService = require(ServerScriptService.server.features.building.BuildingService)
local Building = require(ServerScriptService.server.features.building.class.Building)
local Customer = require(ServerScriptService.server.features.customer.class.Customer)
local CustomerConfig = require(ServerScriptService.server.features.customer.CustomerConfig)
local CustomerService = require(ServerScriptService.server.features.customer.CustomerService)
local CashierConfig = require(ServerScriptService.server.features.cashier.CashierConfig)
local CarWashConfig = require(script.Parent.CarWashConfig)
local EnvironmentService = require(ServerScriptService.server.features.environment.EnvironmentService)

local CarWashService = {}

type Bay = {
	Model: Model,
	Entrance: BasePart,
	Cleaning: BasePart,
	Exit: BasePart,
	HighwayRejoin: BasePart?,
	Customer: Customer.Customer?,
}

type GarageDoorController = {
	SetOpen: (open: boolean) -> (),
}

type PlotWash = {
	Building: Building.Building,
	Bays: { Bay },
	GarageDoorController: GarageDoorController?,
}

local WashesByPlot: { [any]: PlotWash } = {}
local PromptsByCustomer: { [Customer.Customer]: ProximityPrompt } = {}

local function SetGarageDoor(wash: PlotWash, isOpen: boolean)
	local controller = wash.GarageDoorController
	if not controller then
		return
	end

	controller.SetOpen(isOpen)
end

local function IsWashbay(instance: Instance): boolean
	return instance:IsA("Model") and string.sub(instance.Name, 1, #CarWashConfig.WashbayNamePrefix):lower()
		== CarWashConfig.WashbayNamePrefix:lower()
end

local function CreateFallbackPoint(bayModel: Model, index: number): BasePart
	local pointsFolder = bayModel:FindFirstChild(CarWashConfig.PointsFolderName)
	if not pointsFolder then
		pointsFolder = Instance.new("Folder")
		pointsFolder.Name = CarWashConfig.PointsFolderName
		pointsFolder.Parent = bayModel
	end

	local point = pointsFolder:FindFirstChild(`WashbayPoint{index}`)
	if point and point:IsA("BasePart") then
		return point
	end

	local marker = Instance.new("Part")
	marker.Name = `WashbayPoint{index}`
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanTouch = false
	marker.CanQuery = false
	marker.Transparency = 1
	marker.Size = Vector3.new(1, 0.1, 1)
	marker.CFrame = bayModel:GetPivot()
	marker.Parent = pointsFolder
	return marker
end

local function FindPoint(parent: Instance, name: string): BasePart?
	local point = parent:FindFirstChild(name, true)
	return if point and point:IsA("BasePart") then point else nil
end

local function GetBays(buildingModel: Model): { Bay }
	local bays = {}
	local models = {}

	for _, instance in buildingModel:GetChildren() do
		if IsWashbay(instance) then
			table.insert(models, instance :: Model)
		end
	end

	table.sort(models, function(first, second)
		return first.Name < second.Name
	end)

	for index, bayModel in models do
		local fallback = FindPoint(bayModel, `WashbayPoint{index}`) or CreateFallbackPoint(bayModel, index)
		local entrance = FindPoint(bayModel, CarWashConfig.EntrancePointName) or fallback
		local cleaning = FindPoint(bayModel, CarWashConfig.CleaningPointName) or fallback
		local exit = FindPoint(bayModel, CarWashConfig.ExitPointName) or fallback
		local highwayRejoin = FindPoint(bayModel, CarWashConfig.HighwayRejoinPointName)
			or FindPoint(buildingModel, CarWashConfig.HighwayRejoinPointName)

		table.insert(bays, {
			Model = bayModel,
			Entrance = entrance,
			Cleaning = cleaning,
			Exit = exit,
			HighwayRejoin = highwayRejoin,
			Customer = nil,
		})
	end

	return bays
end

local function GetAvailableBay(wash: PlotWash): Bay?
	for _, bay in wash.Bays do
		if not bay.Customer then
			return bay
		end
	end

	return nil
end

local function ReleaseBay(wash: PlotWash, customer: Customer.Customer)
	for _, bay in wash.Bays do
		if bay.Customer == customer then
			bay.Customer = nil
			return
		end
	end
end

local function StartCleaning(bay: Bay, customer: Customer.Customer)
	if bay.Customer ~= customer or customer.Destroyed then
		return
	end

	customer:StartWaiting(CarWashConfig.CleaningSeconds)
	task.delay(CarWashConfig.CleaningSeconds, function()
		if bay.Customer ~= customer or customer.Destroyed or not customer:IsWaiting() then
			return
		end

		local route = {
			{ Building = CarWashConfig.BuildingName, Point = bay.Exit.Name, Part = bay.Exit },
		}
		if bay.HighwayRejoin then
			table.insert(route, {
				Building = CarWashConfig.BuildingName,
				Point = bay.HighwayRejoin.Name,
				Part = bay.HighwayRejoin,
				Trigger = true,
			})
		end
		table.insert(route, { Point = CustomerConfig.HighwayEndName })
		customer:Follow(route)
	end)
end

local function RemoveCustomerPrompt(customer: Customer.Customer)
	local prompt = PromptsByCustomer[customer]
	if not prompt then
		return
	end

	PromptsByCustomer[customer] = nil
	prompt:Destroy()
end

local function SendCustomerToBay(wash: PlotWash, clickedCustomer: Customer.Customer, player: Player)
	if wash.Building.Plot.Owner ~= player then
		return
	end

	local bay = GetAvailableBay(wash)
	local customer = CustomerService.GetFrontCustomer(wash.Building.Plot)
	if not bay or customer ~= clickedCustomer or customer.Destroyed then
		return
	end

	RemoveCustomerPrompt(customer)
	bay.Customer = customer
	CustomerService.RemoveFromQueue(wash.Building.Plot, customer)

	customer.Stopped:Connect(function(pointName: string)
		if pointName == bay.Cleaning.Name then
			StartCleaning(bay, customer)
		end
	end)

	customer.Finished:Connect(function()
		ReleaseBay(wash, customer)
	end)
	if bay.HighwayRejoin then
		customer.Passed:Connect(function(pointName: string)
			if pointName == bay.HighwayRejoin.Name then
				ReleaseBay(wash, customer)
			end
		end)
	end

	customer:Follow({
		{ Building = CarWashConfig.BuildingName, Point = bay.Entrance.Name, Part = bay.Entrance },
		{ Building = CarWashConfig.BuildingName, Point = bay.Cleaning.Name, Part = bay.Cleaning, Stop = true },
	})
end

local function AddCustomerPrompt(wash: PlotWash, customer: Customer.Customer)
	local head = customer.Driver:FindFirstChild("Head", true)
	if not head or not head:IsA("BasePart") then
		return
	end

	RemoveCustomerPrompt(customer)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = CarWashConfig.PromptName
	prompt.ActionText = CarWashConfig.PromptActionText
	prompt.ObjectText = CarWashConfig.PromptObjectText
	prompt.HoldDuration = CarWashConfig.PromptHoldDuration
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 12
	prompt.Parent = head
	PromptsByCustomer[customer] = prompt

	prompt.Triggered:Connect(function(player: Player)
		SendCustomerToBay(wash, customer, player)
	end)
	customer.Departed:Connect(function()
		RemoveCustomerPrompt(customer)
	end)
	customer.Finished:Connect(function()
		RemoveCustomerPrompt(customer)
	end)
end

function CarWashService.Init()
	BuildingService.BuildingAdded:Connect(function(building)
		if building.Name ~= CarWashConfig.BuildingName then
			return
		end

		local wash: PlotWash = {
			Building = building,
			Bays = GetBays(building.Model),
			GarageDoorController = nil,
		}
		local garageDoor = building.Model:FindFirstChild(CarWashConfig.GarageDoorName, true)
		if garageDoor then
			local controllerModule = garageDoor:FindFirstChild("Controller")
			if controllerModule and controllerModule:IsA("ModuleScript") then
				wash.GarageDoorController = require(controllerModule) :: GarageDoorController
			end
		end
		SetGarageDoor(wash, EnvironmentService.IsOpen())
		WashesByPlot[building.Plot] = wash
		building.Plot.Janitor:Add(function()
			WashesByPlot[building.Plot] = nil
		end)
	end)

	CustomerService.CustomerStopped:Connect(function(customer, pointName: string)
		if pointName ~= CashierConfig.StopName then
			return
		end

		local wash = WashesByPlot[customer.Plot]
		if wash and EnvironmentService.IsOpen() then
			AddCustomerPrompt(wash, customer)
		end
	end)

	EnvironmentService.OpenChanged:Connect(function(isOpen: boolean)
		for _, wash in WashesByPlot do
			SetGarageDoor(wash, isOpen)
		end

		if not isOpen then
			for customer, prompt in PromptsByCustomer do
				prompt:Destroy()
				PromptsByCustomer[customer] = nil
			end
			return
		end

		for _, wash in WashesByPlot do
			local customer = CustomerService.GetFrontCustomer(wash.Building.Plot)
			if customer then
				AddCustomerPrompt(wash, customer)
			end
		end
	end)
end

return CarWashService
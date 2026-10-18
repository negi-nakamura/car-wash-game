local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local CustomerConfig = require(script.Parent.Parent.CustomerConfig)
local CustomerDriver = require(script.Parent.Parent.modules.CustomerDriver)

local Templates = ServerStorage:WaitForChild("Assets"):WaitForChild(CustomerConfig.CustomerTemplatesFolderName)
local CustomersFolder = Workspace:WaitForChild(CustomerConfig.CustomersFolderName)

local CustomerBuilder = {}

local function CloneTemplate(name: string): Model
	local template = Templates:FindFirstChild(name)

	return template:Clone()
end

-- Returns the car, its seated driver, and how high the car's pivot sits above the car's bottom.
-- The car's bottom rests on spawnFrame, the same way a building rests on its spawn part.
function CustomerBuilder.Build(spawnFrame: CFrame): (Model, Model, number)
	local car = CloneTemplate(CustomerConfig.CarTemplateName)
	local driver = CloneTemplate(CustomerConfig.DriverTemplateName)

	local seat = car:FindFirstChild(CustomerConfig.DriverSeatName, true)

	local boxCFrame, boxSize = car:GetBoundingBox()
	local pivotHeight = boxSize.Y / 2 - car:GetPivot():ToObjectSpace(boxCFrame).Y

	car:PivotTo(spawnFrame + Vector3.new(0, pivotHeight, 0))
	car.Parent = CustomersFolder
	driver.Parent = CustomersFolder

	CustomerDriver.Sit(driver, seat)

	return car, driver, pivotHeight
end

return CustomerBuilder

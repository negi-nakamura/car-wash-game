local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local CustomerConfig = require(script.Parent.Parent.CustomerConfig)
local CustomerDriver = require(script.Parent.Parent.modules.CustomerDriver)

local Templates = ServerStorage:WaitForChild("Assets"):WaitForChild(CustomerConfig.CustomerTemplatesFolderName)
local CustomersFolder = Workspace:WaitForChild(CustomerConfig.CustomersFolderName)

local CustomerBuilder = {}
local Random = Random.new()

local DriverPalettes = {
	{ Skin = Color3.fromRGB(255, 204, 153), Shirt = Color3.fromRGB(52, 101, 164), Pants = Color3.fromRGB(34, 40, 56) },
	{ Skin = Color3.fromRGB(198, 134, 95), Shirt = Color3.fromRGB(173, 72, 58), Pants = Color3.fromRGB(42, 55, 72) },
	{ Skin = Color3.fromRGB(124, 92, 70), Shirt = Color3.fromRGB(68, 133, 93), Pants = Color3.fromRGB(54, 45, 73) },
	{ Skin = Color3.fromRGB(245, 183, 135), Shirt = Color3.fromRGB(185, 122, 48), Pants = Color3.fromRGB(43, 43, 43) },
}

local function CloneTemplate(name: string): Model
	local template = Templates:FindFirstChild(name)

	return template:Clone()
end

local function CustomizeDriver(driver: Model)
	local humanoid = driver:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	local head = driver:FindFirstChild("Head", true)
	if head and head:IsA("BasePart") then
		local nameTag = Instance.new("BillboardGui")
		nameTag.Name = "DriverNameTag"
		nameTag.Adornee = head
		nameTag.AlwaysOnTop = true
		nameTag.MaxDistance = 80
		nameTag.Size = UDim2.fromOffset(140, 24)
		nameTag.StudsOffset = Vector3.new(0, 3.75, 0)
		nameTag.Parent = head

		local label = Instance.new("TextLabel")
		label.Name = "Name"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.GothamBold
		label.Text = CustomerConfig.DriverNames[Random:NextInteger(1, #CustomerConfig.DriverNames)]
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextScaled = true
		label.TextStrokeColor3 = Color3.fromRGB(25, 25, 25)
		label.TextStrokeTransparency = 0.35
		label.Parent = nameTag
	end

	local bodyColors = driver:FindFirstChildOfClass("BodyColors")
	if not bodyColors then
		return
	end

	local palette = DriverPalettes[Random:NextInteger(1, #DriverPalettes)]
	bodyColors.HeadColor3 = palette.Skin
	bodyColors.LeftArmColor3 = palette.Skin
	bodyColors.RightArmColor3 = palette.Skin
	bodyColors.LeftLegColor3 = palette.Pants
	bodyColors.RightLegColor3 = palette.Pants
	bodyColors.TorsoColor3 = palette.Shirt
end

-- Returns the car, its seated driver, and how high the car's pivot sits above the car's bottom.
-- The car's bottom rests on spawnFrame, the same way a building rests on its spawn part.
function CustomerBuilder.Build(spawnFrame: CFrame): (Model, Model, number)
	local car = CloneTemplate(CustomerConfig.CarTemplateName)
	local driver = CloneTemplate(CustomerConfig.DriverTemplateName)
	CustomizeDriver(driver)

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

local BuildingService = require(script.Parent.BuildingService)

local BillboardService = {}

local function FindFace(model: Model): BasePart?
	local face: BasePart?
	local largestArea = 0

	for _, instance in model:GetChildren() do
		if not instance:IsA("BasePart") then
			continue
		end

		local area = instance.Size.X * instance.Size.Y
		if area > largestArea then
			face = instance
			largestArea = area
		end
	end

	return face
end

local function AddText(parent: Instance, name: string, text: string, position: UDim2, size: UDim2, textSize: number, color: Color3, font: Enum.Font)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Position = position
	label.Size = size
	label.Font = font
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = parent

	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MaxTextSize = textSize
	constraint.Parent = label
end

local function CreateBillboard(building)
	local face = FindFace(building.Model)
	if not face then
		return
	end

	local owner = building.Plot.Owner
	local ownerName = owner and owner.Name or "REPAIR SHOP"

	local gui = Instance.new("SurfaceGui")
	gui.Name = "BillboardGui"
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(700, 360)
	gui.LightInfluence = 0
	gui.Parent = face

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.BackgroundColor3 = Color3.fromRGB(238, 25, 32)
	header.BorderSizePixel = 0
	header.Size = UDim2.fromScale(1, 0.34)
	header.Parent = gui
	AddText(header, "ShopLabel", "SHOP", UDim2.fromScale(0.04, 0.05), UDim2.fromScale(0.92, 0.9), 72, Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold)

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundColor3 = Color3.fromRGB(248, 246, 241)
	body.BorderSizePixel = 0
	body.Position = UDim2.fromScale(0, 0.34)
	body.Size = UDim2.fromScale(1, 0.66)
	body.Parent = gui
	AddText(body, "OwnerLabel", `{ownerName:upper()}'S`, UDim2.fromScale(0.04, 0.17), UDim2.fromScale(0.92, 0.27), 60, Color3.fromRGB(63, 67, 88), Enum.Font.GothamBold)
	AddText(body, "ShopTypeLabel", "CARWASH SHOP", UDim2.fromScale(0.04, 0.45), UDim2.fromScale(0.92, 0.27), 60, Color3.fromRGB(63, 67, 88), Enum.Font.GothamBold)

	gui.Name = "BillboardGuiFront"
	local backGui = gui:Clone()
	backGui.Name = "BillboardGuiBack"
	backGui.Face = Enum.NormalId.Back
	backGui.Parent = face
end

function BillboardService.Init()
	BuildingService.BuildingAdded:Connect(function(building)
		if building.Name == "Billboard" then
			CreateBillboard(building)
		end
	end)
end

return BillboardService
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local NpcConfig = require(script.Parent.NpcConfig)

local Highway = Workspace:WaitForChild(NpcConfig.HighwayFolderName)
local Spawner = Highway:WaitForChild(NpcConfig.SpawnerFolderName)
local PointsFolder = Spawner:FindFirstChild(NpcConfig.PointsFolderName) or Spawner
local Templates = ServerStorage:WaitForChild("Assets"):WaitForChild(NpcConfig.TemplatesFolderName)

local NpcService = {}
local Random = Random.new()
local ActiveNpcs: { [Model]: true } = {}
local PlayerCollisionGroupName = "Players"

local function EnsureCollisionGroup()
	if not PhysicsService:IsCollisionGroupRegistered(NpcConfig.CollisionGroupName) then
		PhysicsService:RegisterCollisionGroup(NpcConfig.CollisionGroupName)
	end
	if not PhysicsService:IsCollisionGroupRegistered(PlayerCollisionGroupName) then
		PhysicsService:RegisterCollisionGroup(PlayerCollisionGroupName)
	end

	PhysicsService:CollisionGroupSetCollidable(NpcConfig.CollisionGroupName, "Default", true)
	PhysicsService:CollisionGroupSetCollidable(NpcConfig.CollisionGroupName, PlayerCollisionGroupName, false)
end

local function SetCollisionGroup(model: Model, groupName: string)
	for _, instance in model:GetDescendants() do
		if instance:IsA("BasePart") then
			instance.CollisionGroup = groupName
		end
	end
end

local function SetPlayerCollisionGroup(player: Player)
	local function OnCharacterAdded(character: Model)
		SetCollisionGroup(character, PlayerCollisionGroupName)
	end

	player.CharacterAdded:Connect(OnCharacterAdded)
	if player.Character then
		OnCharacterAdded(player.Character)
	end
end

type Route = {
	Start: BasePart,
	Finish: BasePart,
}

local function GetRouteNumber(route: Route): number
	return tonumber(string.match(route.Start.Name, "%d+$") or "") or math.huge
end

local function GetRoutes(): { Route }
	local routes = {}

	for _, instance in PointsFolder:GetChildren() do
		if not instance:IsA("BasePart") then
			continue
		end

		local lane = string.match(instance.Name, `^{NpcConfig.StartPointPrefix}(.+)$`)
		if not lane then
			continue
		end

		local finish = PointsFolder:FindFirstChild(NpcConfig.EndPointPrefix .. lane)
		if finish and finish:IsA("BasePart") then
			table.insert(routes, { Start = instance, Finish = finish })
		else
			warn(`[NpcService] Missing matching end point for {instance.Name}`)
		end
	end

	table.sort(routes, function(first, second)
		local firstNumber = GetRouteNumber(first)
		local secondNumber = GetRouteNumber(second)
		if firstNumber == secondNumber then
			return first.Start.Name < second.Start.Name
		end
		return firstNumber < secondNumber
	end)

	return routes
end

local function AddNameTag(model: Model, name: string)
	local head = model:FindFirstChild("Head", true)
	if not head or not head:IsA("BasePart") then
		return
	end

	local tag = Instance.new("BillboardGui")
	tag.Name = "NpcNameTag"
	tag.Adornee = head
	tag.AlwaysOnTop = true
	tag.MaxDistance = NpcConfig.NameTagMaxDistance
	tag.Size = UDim2.fromOffset(120, 32)
	tag.StudsOffset = Vector3.new(0, 2.5, 0)
	tag.Parent = head

	local label = Instance.new("TextLabel")
	label.Name = "Name"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.Text = name
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.TextStrokeColor3 = Color3.fromRGB(25, 25, 25)
	label.TextStrokeTransparency = 0.35
	label.Parent = tag
end

local function DisableRandomMovement(model: Model)
	local scriptInstance = model:FindFirstChild(NpcConfig.RandomMovementScriptName, true)
	if scriptInstance and scriptInstance:IsA("Script") then
		scriptInstance.Disabled = true
	end
end

local function GetBottomOffset(model: Model): number
	local boxCFrame, boxSize = model:GetBoundingBox()
	return model:GetPivot():ToObjectSpace(boxCFrame).Position.Y - boxSize.Y / 2
end

local function PlaceAtPoint(model: Model, point: BasePart, bottomOffset: number)
	local target = point.CFrame * CFrame.new(0, point.Size.Y / 2 - bottomOffset, 0)
	model:PivotTo(target)
end

local function WalkRoute(model: Model, route: Route): boolean
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") then
		return false
	end

	humanoid.WalkSpeed = NpcConfig.WalkSpeed
	local target = route.Finish.Position + Vector3.new(0, route.Finish.Size.Y / 2, 0)

	while ActiveNpcs[model] and model.Parent do
		humanoid:MoveTo(target)
		local reached = humanoid.MoveToFinished:Wait()
		if reached or (root.Position - target).Magnitude <= 3 then
			return true
		end
	end

	return false
end

local function FinishNpc(model: Model, reachedEnd: boolean)
	ActiveNpcs[model] = nil
	if reachedEnd and model.Parent then
		model:Destroy()
	end
end

local function SpawnNpc(routes: { Route })
	local activeCount = 0
	for _ in ActiveNpcs do
		activeCount += 1
	end
	if activeCount >= NpcConfig.MaxNpcs then
		return
	end

	local template = Templates:FindFirstChild(NpcConfig.TemplateName)
	local route = routes[Random:NextInteger(1, #routes)]
	if not template or not template:IsA("Model") or not route then
		warn("[NpcService] Missing NPC driver template or matching highway route")
		return
	end

	local npc = template:Clone()
	npc.Name = `HighwayNpc_{Random:NextInteger(1000, 9999)}`
	DisableRandomMovement(npc)
	npc.Parent = Workspace:FindFirstChild(NpcConfig.NpcFolderName) or Workspace
	ActiveNpcs[npc] = true

	local bottomOffset = GetBottomOffset(npc)
	PlaceAtPoint(npc, route.Start, bottomOffset)
	SetCollisionGroup(npc, NpcConfig.CollisionGroupName)
	AddNameTag(npc, NpcConfig.Names[Random:NextInteger(1, #NpcConfig.Names)])

	task.spawn(function()
		FinishNpc(npc, WalkRoute(npc, route))
	end)
end

function NpcService.Init()
	EnsureCollisionGroup()
	Players.PlayerAdded:Connect(SetPlayerCollisionGroup)
	for _, player in Players:GetPlayers() do
		SetPlayerCollisionGroup(player)
	end

	local npcFolder = Workspace:FindFirstChild(NpcConfig.NpcFolderName)
	if not npcFolder then
		npcFolder = Instance.new("Folder")
		npcFolder.Name = NpcConfig.NpcFolderName
		npcFolder.Parent = Workspace
	end

	local routes = GetRoutes()
	if #routes == 0 then
		warn(`[NpcService] Need matching StartN and EndN BaseParts in {PointsFolder:GetFullName()}`)
		return
	end

	task.spawn(function()
		while true do
			SpawnNpc(routes)
			task.wait(Random:NextNumber(
				NpcConfig.SpawnMinIntervalSeconds,
				NpcConfig.SpawnMaxIntervalSeconds
			))
		end
	end)
end

return NpcService
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local Plot = require(ServerScriptService.server.features.plot.class.Plot)
local Janitor = require(ReplicatedStorage.Packages.janitor)
local Signal = require(ReplicatedStorage.Packages.signal)
local CustomerBuilder = require(script.Parent.Parent.builder.CustomerBuilder)
local CustomerConfig = require(script.Parent.Parent.CustomerConfig)
local CustomerPath = require(script.Parent.Parent.modules.CustomerPath)

local MIN_DISTANCE = 0.01 -- studs; closer than this counts as already at the point

local Customer = {}
Customer.__index = Customer

export type Customer = typeof(setmetatable(
	{} :: {
		Plot: Plot.Plot,
		Car: Model,
		Driver: Model,
		Janitor: typeof(Janitor.new()),
		Destroyed: boolean, -- true after Destroy, so delayed callbacks can skip a customer that is gone
		Stopped: typeof(Signal.new()), -- fires (pointName) when the car arrives at a stop point
		Passed: typeof(Signal.new()), -- fires (pointName) when the car crosses a trigger point
		Departed: typeof(Signal.new()), -- fires (pointName) when the car drives away from a stop point
		Finished: typeof(Signal.new()), -- fires when the car reaches the end of its route
		_Lift: Vector3, -- how far the car's pivot sits above the surface it drives on
		_Route: { CustomerPath.Point },
		_Index: number, -- next point to drive to
		_StopName: string?, -- name of the stop point while the car is parked there
		_Lane: number,
		_WaitingGui: BillboardGui?,
		_WaitingTween: Tween?,
		_WaitingEndsAt: number?,
	},
	Customer
))

function Customer.New(plot: Plot.Plot, laneOverride: number?): Customer
	local lane = CustomerPath.GetLane(plot, laneOverride)
	local car, driver, pivotHeight = CustomerBuilder.Build(CustomerPath.GetSpawnFrame(plot, lane))

	local self = setmetatable({
		Plot = plot,
		Car = car,
		Driver = driver,
		Janitor = Janitor.new(),
		Destroyed = false,
		Stopped = Signal.new(),
		Passed = Signal.new(),
		Departed = Signal.new(),
		Finished = Signal.new(),
		_Lift = Vector3.new(0, pivotHeight, 0),
		_Route = {},
		_Index = 1,
		_StopName = nil,
		_Lane = lane,
		_WaitingGui = nil,
		_WaitingTween = nil,
		_WaitingEndsAt = nil,
	}, Customer)

	self.Janitor:Add(car, "Destroy")
	self.Janitor:Add(driver, "Destroy")
	self.Janitor:Add(self.Stopped, "Destroy")
	self.Janitor:Add(self.Passed, "Destroy")
	self.Janitor:Add(self.Departed, "Destroy")
	self.Janitor:Add(self.Finished, "Destroy")

	return self
end

-- Start a route from where the car is now; replaces the current route, even while parked at a stop
function Customer:Follow(route: { CustomerPath.RouteEntry }, preserveWaiting: boolean?)
	self._Route = CustomerPath.Resolve(self.Plot, route, self._Lane)
	self._Index = 1

	self:_Depart(not preserveWaiting)
	self:_Advance()
end

-- Leave a stop point and carry on with the current route
function Customer:Continue()
	if not self._StopName then
		return
	end

	self:_Depart()
	self:_Advance()
end

function Customer:Destroy()
	self.Destroyed = true
	self:StopWaiting()
	self.Janitor:Destroy()
end

function Customer:StartWaiting(duration: number)
	if self._WaitingEndsAt then
		return
	end

	self:StopWaiting()
	self._WaitingEndsAt = os.clock() + duration

	local head = self.Driver:FindFirstChild("Head", true)
	if not head or not head:IsA("BasePart") then
		return
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = "WaitingLoader"
	gui.Adornee = head
	gui.AlwaysOnTop = true
	gui.MaxDistance = 80
	gui.Size = UDim2.fromOffset(118, 14)
	gui.StudsOffset = Vector3.new(0, 3.25, 0)
	gui.Parent = head

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.BackgroundColor3 = Color3.fromRGB(28, 32, 40)
	background.BorderSizePixel = 0
	background.Size = UDim2.fromScale(1, 1)
	background.Parent = gui

	local backgroundCorner = Instance.new("UICorner")
	backgroundCorner.CornerRadius = UDim.new(0, 7)
	backgroundCorner.Parent = background

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = Color3.fromRGB(87, 210, 137)
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(1, 1)
	fill.Parent = background

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 7)
	fillCorner.Parent = fill

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.7
	stroke.Parent = background

	self._WaitingGui = gui
	self._WaitingTween = TweenService:Create(
		fill,
		TweenInfo.new(duration, Enum.EasingStyle.Linear),
		{ Size = UDim2.fromScale(0, 1) }
	)
	self._WaitingTween:Play()
end

function Customer:GetWaitingRemaining(): number
	if not self._WaitingEndsAt then
		return 0
	end

	return math.max(self._WaitingEndsAt - os.clock(), 0)
end

function Customer:IsWaiting(): boolean
	return self._WaitingEndsAt ~= nil
end

function Customer:StopWaiting()
	if self._WaitingTween then
		self._WaitingTween:Cancel()
		self._WaitingTween = nil
	end
	if self._WaitingGui then
		self._WaitingGui:Destroy()
		self._WaitingGui = nil
	end
	self._WaitingEndsAt = nil
end

-- Fire Departed when the car leaves the stop point it was parked at
function Customer:_Depart(stopWaiting: boolean?): string?
	local stopName = self._StopName

	if stopName then
		self._StopName = nil
		if stopWaiting ~= false then
			self:StopWaiting()
		end
		self.Departed:Fire(stopName)
	end

	return stopName
end

-- Turn in place towards the next point, then drive straight to it
function Customer:_Advance()
	local point = self._Route[self._Index]

	if not point then
		self.Finished:Fire()
		return
	end

	local pivot = self.Car:GetPivot()
	local goalPosition = point.Position + self._Lift
	local offset = goalPosition - pivot.Position
	local flatOffset = Vector3.new(offset.X, 0, offset.Z)

	if flatOffset.Magnitude < MIN_DISTANCE then
		self:_Arrive(point)
		return
	end

	-- Y rotation only, the car stays level
	local goalRotation = CFrame.lookAt(Vector3.zero, flatOffset)
	local turnAngle = math.deg(math.acos(math.clamp(pivot.LookVector:Dot(goalRotation.LookVector), -1, 1)))
	local smooth = not CustomerConfig.InstantMovementPoints[point.Name]

	self:_Tween(CFrame.new(pivot.Position) * goalRotation, turnAngle / CustomerConfig.TurnSpeed, function()
		self:_Tween(
			CFrame.new(goalPosition) * goalRotation,
			offset.Magnitude / CustomerConfig.CarSpeed,
			function()
			self:_Arrive(point)
			end,
			smooth
		)
	end)
end

function Customer:_Arrive(point: CustomerPath.Point)
	self._Index += 1

	if point.Trigger then
		self.Passed:Fire(point.Name)
	end

	if point.Stop then
		self._StopName = point.Name
		self.Stopped:Fire(point.Name)
	else
		self:_Advance()
	end
end

-- Move the car to goal over duration seconds, then call onDone; starting a new tween cancels the old one
function Customer:_Tween(goal: CFrame, duration: number, onDone: () -> (), smooth: boolean?)
	if duration <= 0 then
		self.Car:PivotTo(goal)
		onDone()
		return
	end

	-- A Model has no CFrame property, so tween a CFrameValue and pivot the car with it
	local value = Instance.new("CFrameValue")
	value.Value = self.Car:GetPivot()

	self.Janitor:Add(value, "Destroy", "MoveValue")
	self.Janitor:Add(value.Changed:Connect(function(cframe: CFrame)
		self.Car:PivotTo(cframe)
	end), "Disconnect", "MoveChanged")

	local function PlayPhase(
		phaseGoal: CFrame,
		phaseDuration: number,
		easingStyle: Enum.EasingStyle,
		easingDirection: Enum.EasingDirection,
		janitorKey: string,
		onPhaseDone: () -> ()
	)
		local tween = TweenService:Create(
			value,
			TweenInfo.new(phaseDuration, easingStyle, easingDirection),
			{ Value = phaseGoal }
		)

		self.Janitor:Add(tween, "Cancel", janitorKey)
		tween.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed then
				onPhaseDone()
			end
		end)
		tween:Play()
	end

	if not smooth then
		PlayPhase(goal, duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, "Move", onDone)
		return
	end

	local accelerationDuration = math.min(CustomerConfig.AccelerationSeconds, duration / 2)
	local decelerationDuration = math.min(CustomerConfig.DecelerationSeconds, duration / 2)
	local accelerationFraction = accelerationDuration / (2 * duration)
	local decelerationFraction = decelerationDuration / (2 * duration)
	local accelerationGoal = value.Value:Lerp(goal, accelerationFraction)
	local decelerationStart = value.Value:Lerp(goal, 1 - decelerationFraction)

	PlayPhase(accelerationGoal, accelerationDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In, "MoveAcceleration", function()
		PlayPhase(
			decelerationStart,
			duration - (accelerationDuration + decelerationDuration) / 2,
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out,
			"MoveCruise",
			function()
				PlayPhase(
					goal,
					decelerationDuration,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.Out,
					"MoveDeceleration",
					onDone
				)
			end
		)
	end)
end

return Customer

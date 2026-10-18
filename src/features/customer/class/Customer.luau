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
		Departed: typeof(Signal.new()), -- fires (pointName) when the car drives away from a stop point
		Finished: typeof(Signal.new()), -- fires when the car reaches the end of its route
		_Lift: Vector3, -- how far the car's pivot sits above the surface it drives on
		_Route: { CustomerPath.Point },
		_Index: number, -- next point to drive to
		_StopName: string?, -- name of the stop point while the car is parked there
	},
	Customer
))

function Customer.New(plot: Plot.Plot): Customer
	local car, driver, pivotHeight = CustomerBuilder.Build(CustomerPath.GetSpawnFrame())

	local self = setmetatable({
		Plot = plot,
		Car = car,
		Driver = driver,
		Janitor = Janitor.new(),
		Destroyed = false,
		Stopped = Signal.new(),
		Departed = Signal.new(),
		Finished = Signal.new(),
		_Lift = Vector3.new(0, pivotHeight, 0),
		_Route = {},
		_Index = 1,
		_StopName = nil,
	}, Customer)

	self.Janitor:Add(car, "Destroy")
	self.Janitor:Add(driver, "Destroy")
	self.Janitor:Add(self.Stopped, "Destroy")
	self.Janitor:Add(self.Departed, "Destroy")
	self.Janitor:Add(self.Finished, "Destroy")

	return self
end

-- Start a route from where the car is now; replaces the current route, even while parked at a stop
function Customer:Follow(route: { CustomerPath.RouteEntry })
	self._Route = CustomerPath.Resolve(self.Plot, route)
	self._Index = 1

	self:_Depart()
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
	self.Janitor:Destroy()
end

-- Fire Departed when the car leaves the stop point it was parked at
function Customer:_Depart()
	local stopName = self._StopName

	if stopName then
		self._StopName = nil
		self.Departed:Fire(stopName)
	end
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

	self:_Tween(CFrame.new(pivot.Position) * goalRotation, turnAngle / CustomerConfig.TurnSpeed, function()
		self:_Tween(CFrame.new(goalPosition) * goalRotation, offset.Magnitude / CustomerConfig.CarSpeed, function()
			self:_Arrive(point)
		end)
	end)
end

function Customer:_Arrive(point: CustomerPath.Point)
	self._Index += 1

	if point.Stop then
		self._StopName = point.Name
		self.Stopped:Fire(point.Name)
	else
		self:_Advance()
	end
end

-- Move the car to goal over duration seconds, then call onDone; starting a new tween cancels the old one
function Customer:_Tween(goal: CFrame, duration: number, onDone: () -> ())
	if duration <= 0 then
		self.Car:PivotTo(goal)
		onDone()
		return
	end

	-- A Model has no CFrame property, so tween a CFrameValue and pivot the car with it
	local value = Instance.new("CFrameValue")
	value.Value = self.Car:GetPivot()

	local tween = TweenService:Create(value, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Value = goal })

	self.Janitor:Add(value, "Destroy", "MoveValue")
	self.Janitor:Add(value.Changed:Connect(function(cframe: CFrame)
		self.Car:PivotTo(cframe)
	end), "Disconnect", "MoveChanged")
	self.Janitor:Add(tween, "Cancel", "Move")

	tween.Completed:Once(function(state: Enum.PlaybackState)
		if state == Enum.PlaybackState.Completed then
			onDone()
		end
	end)

	tween:Play()
end

return Customer

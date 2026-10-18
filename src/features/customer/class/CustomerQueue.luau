local CustomerConfig = require(script.Parent.Parent.CustomerConfig)
local CustomerPath = require(script.Parent.Parent.modules.CustomerPath)
local Customer = require(script.Parent.Customer)

local CustomerQueue = {}
CustomerQueue.__index = CustomerQueue

export type CustomerQueue = typeof(setmetatable(
	{} :: {
		_Line: { Customer.Customer }, -- the front of the queue first
		_ParkedAt: { [Customer.Customer]: string }, -- the queue point each parked customer stands on
	},
	CustomerQueue
))

-- Every queue point is a stop, so the service hears when a car arrives
local function QueueEntry(pointName: string): CustomerPath.RouteEntry
	return { Building = CustomerConfig.LaneBuilding, Point = pointName, Stop = true }
end

function CustomerQueue.New(): CustomerQueue
	return setmetatable({
		_Line = {},
		_ParkedAt = {},
	}, CustomerQueue)
end

function CustomerQueue:IsFull(): boolean
	return #self._Line >= #CustomerConfig.QueuePoints
end

function CustomerQueue:IsEmpty(): boolean
	return #self._Line == 0
end

function CustomerQueue:GetFront(): Customer.Customer?
	return self._Line[1]
end

function CustomerQueue:GetCustomers(): { Customer.Customer }
	return table.clone(self._Line)
end

function CustomerQueue:IsParked(customer: Customer.Customer): boolean
	return self._ParkedAt[customer] ~= nil
end

function CustomerQueue:Remove(customer: Customer.Customer)
	local index = table.find(self._Line, customer)
	if not index then
		return
	end

	table.remove(self._Line, index)
	self._ParkedAt[customer] = nil
	self:_Advance()
end

-- Take the back slot and drive there from the lane entrance
function CustomerQueue:Join(customer: Customer.Customer)
	table.insert(self._Line, customer)

	customer:Follow({
		{ Building = CustomerConfig.LaneBuilding, Point = CustomerConfig.LaneEntrancePoint },
		QueueEntry(CustomerConfig.QueuePoints[#self._Line]),
	})
end

-- The customer parked on a queue point; if a slot ahead is free, move forward
function CustomerQueue:Parked(customer: Customer.Customer, pointName: string)
	if pointName == CustomerConfig.LaneExitPoint
		or pointName == CustomerConfig.LaneExitCheckPoint
		or pointName == CustomerConfig.LaneRejoinPoint
	then
		return
	end

	self._ParkedAt[customer] = pointName
	customer:StartWaiting(CustomerConfig.QueueWaitSeconds)
	self:_Advance()
end

-- The customer drove away from a queue point; leaving the front point means leaving the queue
function CustomerQueue:Departed(customer: Customer.Customer, pointName: string)
	self._ParkedAt[customer] = nil

	if pointName == CustomerConfig.LaneExitCheckPoint then
		table.remove(self._Line, table.find(self._Line, customer))
		self:_Advance()
	end
end

-- Every parked customer drives up to the slot matching its place in line
function CustomerQueue:_Advance()
	for index, customer in self._Line do
		local slot = CustomerConfig.QueuePoints[index]
		local parkedAt = self._ParkedAt[customer]

		if parkedAt and parkedAt ~= slot then
			customer:Follow({ QueueEntry(slot) }, true)
		end
	end
end

return CustomerQueue

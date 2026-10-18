local ServerScriptService = game:GetService("ServerScriptService")

local CustomerConfig = require(ServerScriptService.server.features.customer.CustomerConfig)
local CustomerService = require(ServerScriptService.server.features.customer.CustomerService)
local CashierConfig = require(script.Parent.CashierConfig)

local CashierService = {}

function CashierService.Init()
	CustomerService.CustomerStopped:Connect(function(customer, pointName: string)
		if pointName == CustomerConfig.LaneExitPoint
			or pointName == CustomerConfig.LaneRejoinPoint
		then
			customer:Continue()
			return
		end

		if pointName ~= CashierConfig.StopName then
			return
		end

		customer:StartWaiting(CustomerConfig.QueueWaitSeconds)

		-- Wait for the customer's queue timer to finish before sending them out.
		task.delay(customer:GetWaitingRemaining(), function()
			if not customer.Destroyed and customer:IsWaiting() and customer:GetWaitingRemaining() <= 0 then
				customer:Follow(CustomerConfig.RejectRoute)
			end
		end)
	end)
end

return CashierService

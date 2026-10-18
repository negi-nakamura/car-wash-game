local ServerScriptService = game:GetService("ServerScriptService")

local CustomerConfig = require(ServerScriptService.server.features.customer.CustomerConfig)
local CustomerService = require(ServerScriptService.server.features.customer.CustomerService)
local CashierConfig = require(script.Parent.CashierConfig)

local CashierService = {}

function CashierService.Init()
	CustomerService.CustomerStopped:Connect(function(customer, pointName: string)
		if pointName == CustomerConfig.LaneExitPoint
			or pointName == CustomerConfig.LaneExitCheckPoint
			or pointName == CustomerConfig.LaneRejoinPoint
		then
			customer:Continue()
			return
		end

		if pointName ~= CashierConfig.StopName then
			return
		end

		-- Test timer: reject the front customer, later this is where the order and payment happen
		task.delay(CashierConfig.DecisionSeconds, function()
			if not customer.Destroyed then
				customer:Follow(CustomerConfig.RejectRoute)
			end
		end)
	end)
end

return CashierService

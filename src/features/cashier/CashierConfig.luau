return table.freeze({
	-- Customer stop
	StopName = "CashierStop", -- the lane point where the front customer is served

	-- Placeholder until payment exists
	DecisionSeconds = 5, -- seconds the front customer waits before being rejected
})

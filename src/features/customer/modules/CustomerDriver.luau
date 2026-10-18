local CustomerDriver = {}

function CustomerDriver.Sit(driver: Model, seat: Seat)
	local humanoid = driver:FindFirstChildOfClass("Humanoid")

	seat:Sit(humanoid)
end

return CustomerDriver

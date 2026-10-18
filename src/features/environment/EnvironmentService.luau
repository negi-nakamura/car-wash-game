local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnvironmentConfig = require(script.Parent.EnvironmentConfig)

local Signal = require(ReplicatedStorage.Packages.signal)

local EnvironmentService = {}

EnvironmentService.OpenChanged = Signal.new()

local CurrentClockTime = EnvironmentConfig.DayStartClockTime
local ShopOpen = true

local function IsNight(clockTime: number): boolean
	return clockTime >= EnvironmentConfig.NightStartClockTime or clockTime < EnvironmentConfig.DayStartClockTime
end

function EnvironmentService.IsOpen(): boolean
	return ShopOpen
end

local function SetMarkedLights(enabled: boolean)
	for _, instance in Workspace:GetDescendants() do
		if instance:IsA("Light") and instance:GetAttribute("Light") == true then
			instance.Enabled = enabled
		end
	end
end

function EnvironmentService.Init()
	task.spawn(function()
		local startedAt = os.clock()

		while true do
			local elapsed = (os.clock() - startedAt) % EnvironmentConfig.CycleSeconds
			local clockTime = (EnvironmentConfig.DayStartClockTime + elapsed / EnvironmentConfig.CycleSeconds * 24) % 24
			local wasOpen = ShopOpen
			ShopOpen = not IsNight(clockTime)
			CurrentClockTime = clockTime

			Lighting.ClockTime = clockTime
			SetMarkedLights(not ShopOpen)
			if ShopOpen ~= wasOpen then
				EnvironmentService.OpenChanged:Fire(ShopOpen, CurrentClockTime)
			end
			task.wait(EnvironmentConfig.UpdateIntervalSeconds)
		end
	end)
end

return EnvironmentService
--[[
	CurrencyHUD.client.luau — Always-visible currency display at the top of the screen.
	Shows current Viewers count and egg/job slot counts.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local stateFolder = playerGui:WaitForChild("ClientState")
local dataChangedEvent = stateFolder:WaitForChild("DataChanged")

local mainUI = playerGui:WaitForChild("MainUI")

--------------------------------------------------------------------------------
-- Build HUD
--------------------------------------------------------------------------------

local hud = Instance.new("Frame")
hud.Name = "CurrencyHUD"
hud.Size = UDim2.new(0, 300, 0, 40)
hud.Position = UDim2.new(0.5, -150, 0, 8)
hud.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
hud.BackgroundTransparency = 0.15
hud.BorderSizePixel = 0
hud.ZIndex = 20
hud.Parent = mainUI

Instance.new("UICorner", hud).CornerRadius = UDim.new(0, 10)

local currencyIcon = Instance.new("TextLabel")
currencyIcon.Size = UDim2.new(0, 30, 1, 0)
currencyIcon.Position = UDim2.new(0, 8, 0, 0)
currencyIcon.BackgroundTransparency = 1
currencyIcon.Text = "👁"
currencyIcon.TextSize = 20
currencyIcon.ZIndex = 21
currencyIcon.Parent = hud

local currencyLabel = Instance.new("TextLabel")
currencyLabel.Name = "CurrencyLabel"
currencyLabel.Size = UDim2.new(0, 100, 1, 0)
currencyLabel.Position = UDim2.new(0, 36, 0, 0)
currencyLabel.BackgroundTransparency = 1
currencyLabel.Text = "0"
currencyLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
currencyLabel.TextSize = 18
currencyLabel.Font = Enum.Font.GothamBold
currencyLabel.TextXAlignment = Enum.TextXAlignment.Left
currencyLabel.ZIndex = 21
currencyLabel.Parent = hud

local slotsInfo = Instance.new("TextLabel")
slotsInfo.Name = "SlotsInfo"
slotsInfo.Size = UDim2.new(0, 150, 1, 0)
slotsInfo.Position = UDim2.new(1, -158, 0, 0)
slotsInfo.BackgroundTransparency = 1
slotsInfo.Text = "🥚 0/10 | 📺 0/2"
slotsInfo.TextColor3 = Color3.fromRGB(180, 180, 200)
slotsInfo.TextSize = 12
slotsInfo.Font = Enum.Font.Gotham
slotsInfo.TextXAlignment = Enum.TextXAlignment.Right
slotsInfo.ZIndex = 21
slotsInfo.Parent = hud

--------------------------------------------------------------------------------
-- Update on data change
--------------------------------------------------------------------------------

dataChangedEvent.Event:Connect(function(data)
	if not data then return end

	-- Format currency with commas
	local formatted = tostring(math.floor(data.currency))
	-- Simple comma formatting
	local result = ""
	local len = #formatted
	for i = 1, len do
		if i > 1 and (len - i + 1) % 3 == 0 then
			result = result .. ","
		end
		result = result .. formatted:sub(i, i)
	end
	currencyLabel.Text = result

	slotsInfo.Text = string.format(
		"🥚 %d/%d | 📺 %d/%d",
		#data.eggs, data.eggSlotsCap,
		#data.workers, data.jobSlotsCap
	)
end)

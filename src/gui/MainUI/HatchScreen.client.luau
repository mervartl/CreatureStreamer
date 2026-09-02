--[[
	HatchScreen.client.luau — Hatch button, cost display, result feedback.
	Lives inside MainUI ScreenGui.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TierData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TierData"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for ClientState bridge from init.client.luau
local stateFolder = playerGui:WaitForChild("ClientState")
local dataChangedEvent = stateFolder:WaitForChild("DataChanged")
local Remotes = stateFolder:WaitForChild("RemotesRef").Value

local HatchEgg = Remotes:WaitForChild("HatchEgg")

-- Get the MainUI ScreenGui
local mainUI = playerGui:WaitForChild("MainUI")

--------------------------------------------------------------------------------
-- Build UI
--------------------------------------------------------------------------------

local frame = Instance.new("Frame")
frame.Name = "HatchFrame"
frame.Size = UDim2.new(0, 220, 0, 280)
frame.Position = UDim2.new(0, 20, 1, -300)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Parent = mainUI

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 36)
title.Position = UDim2.new(0, 0, 0, 8)
title.BackgroundTransparency = 1
title.Text = "🥚 Hatch Egg"
title.TextColor3 = Color3.fromRGB(255, 220, 80)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.Parent = frame

local costLabel = Instance.new("TextLabel")
costLabel.Name = "CostLabel"
costLabel.Size = UDim2.new(1, -20, 0, 24)
costLabel.Position = UDim2.new(0, 10, 0, 48)
costLabel.BackgroundTransparency = 1
costLabel.Text = "Cost: " .. Config.HATCH_COST .. " Viewers"
costLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
costLabel.TextSize = 14
costLabel.Font = Enum.Font.Gotham
costLabel.TextXAlignment = Enum.TextXAlignment.Left
costLabel.Parent = frame

local slotsLabel = Instance.new("TextLabel")
slotsLabel.Name = "SlotsLabel"
slotsLabel.Size = UDim2.new(1, -20, 0, 24)
slotsLabel.Position = UDim2.new(0, 10, 0, 72)
slotsLabel.BackgroundTransparency = 1
slotsLabel.Text = "Slots: --/--"
slotsLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
slotsLabel.TextSize = 14
slotsLabel.Font = Enum.Font.Gotham
slotsLabel.TextXAlignment = Enum.TextXAlignment.Left
slotsLabel.Parent = frame

local hatchButton = Instance.new("TextButton")
hatchButton.Name = "HatchButton"
hatchButton.Size = UDim2.new(1, -30, 0, 44)
hatchButton.Position = UDim2.new(0, 15, 0, 106)
hatchButton.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
hatchButton.Text = "🐣 HATCH!"
hatchButton.TextColor3 = Color3.fromRGB(255, 255, 255)
hatchButton.TextSize = 18
hatchButton.Font = Enum.Font.GothamBold
hatchButton.AutoButtonColor = true
hatchButton.Parent = frame

local hatchCorner = Instance.new("UICorner")
hatchCorner.CornerRadius = UDim.new(0, 8)
hatchCorner.Parent = hatchButton

local resultLabel = Instance.new("TextLabel")
resultLabel.Name = "ResultLabel"
resultLabel.Size = UDim2.new(1, -20, 0, 60)
resultLabel.Position = UDim2.new(0, 10, 0, 160)
resultLabel.BackgroundTransparency = 1
resultLabel.Text = ""
resultLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
resultLabel.TextSize = 16
resultLabel.Font = Enum.Font.GothamBold
resultLabel.TextWrapped = true
resultLabel.Parent = frame

-- Odds button (opens OddsDetailsPopup)
local oddsButton = Instance.new("TextButton")
oddsButton.Name = "OddsButton"
oddsButton.Size = UDim2.new(1, -30, 0, 30)
oddsButton.Position = UDim2.new(0, 15, 1, -40)
oddsButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
oddsButton.Text = "📊 View Odds"
oddsButton.TextColor3 = Color3.fromRGB(160, 180, 255)
oddsButton.TextSize = 13
oddsButton.Font = Enum.Font.Gotham
oddsButton.AutoButtonColor = true
oddsButton.Parent = frame

local oddsCorner = Instance.new("UICorner")
oddsCorner.CornerRadius = UDim.new(0, 6)
oddsCorner.Parent = oddsButton

--------------------------------------------------------------------------------
-- Logic
--------------------------------------------------------------------------------

local debounce = false

hatchButton.MouseButton1Click:Connect(function()
	if debounce then return end
	debounce = true

	resultLabel.Text = "Hatching..."
	resultLabel.TextColor3 = Color3.fromRGB(200, 200, 200)

	local success, result = HatchEgg:InvokeServer()

	if success then
		local tierInfo = TierData.get(result.tier)
		resultLabel.Text = "✨ " .. tierInfo.displayName .. "!"
		resultLabel.TextColor3 = tierInfo.color
	else
		resultLabel.Text = "❌ " .. tostring(result)
		resultLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	end

	task.wait(0.3)
	debounce = false
end)

-- Open odds popup
oddsButton.MouseButton1Click:Connect(function()
	local oddsPopup = mainUI:FindFirstChild("OddsPopupFrame")
	if oddsPopup then
		oddsPopup.Visible = not oddsPopup.Visible
	end
end)

-- Update display when data changes
dataChangedEvent.Event:Connect(function(data)
	if data then
		slotsLabel.Text = "Slots: " .. #data.eggs .. "/" .. data.eggSlotsCap
		local canAfford = data.currency >= Config.HATCH_COST
		local hasRoom = #data.eggs < data.eggSlotsCap
		hatchButton.BackgroundColor3 = if (canAfford and hasRoom)
			then Color3.fromRGB(80, 180, 80)
			else Color3.fromRGB(100, 100, 100)
	end
end)

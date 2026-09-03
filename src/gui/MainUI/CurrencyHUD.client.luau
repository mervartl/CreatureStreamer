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
mainUI.IgnoreGuiInset = true
local ScreenManager = require(script.Parent:WaitForChild("ScreenManager"))

--------------------------------------------------------------------------------
-- Build HUD
--------------------------------------------------------------------------------

local hud = Instance.new("Frame")
hud.Name = "CurrencyHUD"
hud.Size = UDim2.new(0, 500, 0, 48)
hud.AnchorPoint = Vector2.new(0.5, 0)
hud.Position = UDim2.new(0.5, 0, 0, 12)
hud.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
hud.BackgroundTransparency = 0.15
hud.BorderSizePixel = 0
hud.ZIndex = 20
hud.Parent = mainUI

local hudConstraint = Instance.new("UISizeConstraint")
hudConstraint.MaxSize = Vector2.new(600, 48)
hudConstraint.Parent = hud

local uiScale = Instance.new("UIScale")
uiScale.Scale = 1.0
uiScale.Parent = hud

Instance.new("UICorner", hud).CornerRadius = UDim.new(0, 10)

local currencyIcon = Instance.new("TextLabel")
currencyIcon.Size = UDim2.new(0, 30, 1, 0)
currencyIcon.Position = UDim2.new(0, 10, 0, 0)
currencyIcon.BackgroundTransparency = 1
currencyIcon.Text = "👁"
currencyIcon.TextSize = 24
currencyIcon.ZIndex = 21
currencyIcon.Parent = hud

local currencyLabel = Instance.new("TextLabel")
currencyLabel.Name = "CurrencyLabel"
currencyLabel.Size = UDim2.new(0, 150, 1, 0)
currencyLabel.Position = UDim2.new(0, 40, 0, 0)
currencyLabel.BackgroundTransparency = 1
currencyLabel.Text = "0"
currencyLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
currencyLabel.TextSize = 20
currencyLabel.Font = Enum.Font.GothamBold
currencyLabel.TextXAlignment = Enum.TextXAlignment.Left
currencyLabel.ZIndex = 21
currencyLabel.Parent = hud

local slotsInfo = Instance.new("TextLabel")
slotsInfo.Name = "SlotsInfo"
slotsInfo.Size = UDim2.new(0, 150, 1, 0)
slotsInfo.Position = UDim2.new(1, -260, 0, 0)
slotsInfo.BackgroundTransparency = 1
slotsInfo.Text = "🥚 0/10 | 📺 0/2"
slotsInfo.TextColor3 = Color3.fromRGB(180, 180, 200)
slotsInfo.TextSize = 14
slotsInfo.Font = Enum.Font.Gotham
slotsInfo.TextXAlignment = Enum.TextXAlignment.Right
slotsInfo.ZIndex = 21
slotsInfo.Parent = hud

local oddsButton = Instance.new("TextButton")
oddsButton.Name = "OddsButton"
oddsButton.Size = UDim2.new(0, 100, 0, 32)
oddsButton.Position = UDim2.new(1, -108, 0.5, -16)
oddsButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
oddsButton.Text = "📊 View Odds"
oddsButton.TextColor3 = Color3.fromRGB(160, 180, 255)
oddsButton.TextSize = 13
oddsButton.Font = Enum.Font.Gotham
oddsButton.AutoButtonColor = true
oddsButton.ZIndex = 22
oddsButton.Parent = hud

Instance.new("UICorner", oddsButton).CornerRadius = UDim.new(0, 4)

oddsButton.MouseButton1Click:Connect(function()
	local oddsPopup = mainUI:FindFirstChild("OddsPopupFrame")
	if oddsPopup then
		oddsPopup.Visible = not oddsPopup.Visible
	end
end)

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

--------------------------------------------------------------------------------
-- Responsive Layout
--------------------------------------------------------------------------------

local function applyScreen(info)
	uiScale.Scale = info.scale
	if info.deviceClass == "Mobile" then
		hud.Position = UDim2.new(0.58, 0, 0, 10)
		hud.Size = UDim2.new(0, 420, 0, 40)
		hudConstraint.MaxSize = Vector2.new(440, 40)
	elseif info.deviceClass == "Tablet" then
		hud.Position = UDim2.new(0.5, 0, 0, 12)
		hud.Size = UDim2.new(0, 480, 0, 48)
		hudConstraint.MaxSize = Vector2.new(500, 48)
	else
		hud.Position = UDim2.new(0.5, 0, 0, 12)
		hud.Size = UDim2.new(0, 540, 0, 48)
		hudConstraint.MaxSize = Vector2.new(600, 48)
	end
end

ScreenManager.ScreenChanged:Connect(applyScreen)
-- Apply immediately for initial load
if ScreenManager.CurrentClass then
	applyScreen({
		deviceClass = ScreenManager.CurrentClass,
		scale = ScreenManager.CurrentScale
	})
end

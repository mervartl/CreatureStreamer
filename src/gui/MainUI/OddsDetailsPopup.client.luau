--[[
	OddsDetailsPopup.client.luau — Required odds disclosure UI.
	Shows exact numerical probabilities for each hatch tier outcome,
	dynamically recalculated when the Luck pass is active.
	Roblox policy requirement for any paid random outcome.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TierData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TierData"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local RarityUtil = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RarityUtil"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local stateFolder = playerGui:WaitForChild("ClientState")
local dataChangedEvent = stateFolder:WaitForChild("DataChanged")

local mainUI = playerGui:WaitForChild("MainUI")
local ScreenManager = require(script.Parent:WaitForChild("ScreenManager"))

--------------------------------------------------------------------------------
-- Build UI
--------------------------------------------------------------------------------

local frame = Instance.new("Frame")
frame.Name = "OddsPopupFrame"
frame.Size = UDim2.new(0, 360, 0, 400) -- Celkové zvětšení okna (bylo 300x340)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)  -- perfectly centered on all screens
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
frame.BackgroundTransparency = 0.02
frame.BorderSizePixel = 0
frame.Visible = false  -- toggled from HatchScreen
frame.ZIndex = 10
frame.Parent = mainUI

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local uiScale = Instance.new("UIScale")
uiScale.Scale = 1.0
uiScale.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 32)
title.Position = UDim2.new(0, 0, 0, 8)
title.BackgroundTransparency = 1
title.Text = "📊 Hatch Odds Disclosure"
title.TextColor3 = Color3.fromRGB(255, 200, 80)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.ZIndex = 11
title.Parent = frame

local luckLabel = Instance.new("TextLabel")
luckLabel.Name = "LuckLabel"
luckLabel.Size = UDim2.new(1, -20, 0, 18)
luckLabel.Position = UDim2.new(0, 10, 0, 40)
luckLabel.BackgroundTransparency = 1
luckLabel.Text = "Current Luck: 1.0x"
luckLabel.TextColor3 = Color3.fromRGB(120, 220, 120)
luckLabel.TextSize = 12
luckLabel.Font = Enum.Font.GothamBold
luckLabel.TextXAlignment = Enum.TextXAlignment.Left
luckLabel.ZIndex = 11
luckLabel.Parent = frame

local passLabel = Instance.new("TextLabel")
passLabel.Name = "PassLabel"
passLabel.Size = UDim2.new(1, -20, 0, 16)
passLabel.Position = UDim2.new(0, 10, 0, 58)
passLabel.BackgroundTransparency = 1
passLabel.Text = "🍀 2x Luck Pass: Not Owned"
passLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
passLabel.TextSize = 11
passLabel.Font = Enum.Font.Gotham
passLabel.TextXAlignment = Enum.TextXAlignment.Left
passLabel.ZIndex = 11
passLabel.Parent = frame

-- Header row
local headerRow = Instance.new("Frame")
headerRow.Size = UDim2.new(1, -20, 0, 22)
headerRow.Position = UDim2.new(0, 10, 0, 82)
headerRow.BackgroundTransparency = 1
headerRow.ZIndex = 11
headerRow.Parent = frame

local headerTier = Instance.new("TextLabel")
headerTier.Size = UDim2.new(0.5, 0, 1, 0)
headerTier.BackgroundTransparency = 1
headerTier.Text = "Tier"
headerTier.TextColor3 = Color3.fromRGB(180, 180, 200)
headerTier.TextSize = 12
headerTier.Font = Enum.Font.GothamBold
headerTier.TextXAlignment = Enum.TextXAlignment.Left
headerTier.ZIndex = 11
headerTier.Parent = headerRow

local headerOdds = Instance.new("TextLabel")
headerOdds.Size = UDim2.new(0.5, 0, 1, 0)
headerOdds.Position = UDim2.new(0.5, 0, 0, 0)
headerOdds.BackgroundTransparency = 1
headerOdds.Text = "Probability"
headerOdds.TextColor3 = Color3.fromRGB(180, 180, 200)
headerOdds.TextSize = 12
headerOdds.Font = Enum.Font.GothamBold
headerOdds.TextXAlignment = Enum.TextXAlignment.Right
headerOdds.ZIndex = 11
headerOdds.Parent = headerRow

-- Scrolling list for odds rows
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "OddsList"
scrollFrame.Size = UDim2.new(1, -20, 1, -140)
scrollFrame.Position = UDim2.new(0, 10, 0, 108)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 4
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ZIndex = 11
scrollFrame.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 2)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollFrame

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -34, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 12
closeBtn.Parent = frame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

closeBtn.MouseButton1Click:Connect(function()
	frame.Visible = false
end)

--------------------------------------------------------------------------------
-- Render odds table
--------------------------------------------------------------------------------

local function renderOdds(data)
	-- Clear existing rows
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Calculate effective luck
	local luck = Config.BASE_LUCK
	local ceilingLevel = 0
	local floorLevel = 0
	if data then
		luck = data.luck or Config.BASE_LUCK
		if data.hasLuckPass then
			luck = luck * Config.LUCK_PASS_MULTIPLIER
		end
		luck = luck + (data.sessionLuckBoost or 0)
		ceilingLevel = data.ceilingLevel or 0
		floorLevel = data.floorLevel or 0

		luckLabel.Text = string.format("Current Luck: %.1fx", luck)
		passLabel.Text = data.hasLuckPass
			and "🍀 2x Luck Pass: ✅ Active"
			or "🍀 2x Luck Pass: Not Owned"
		passLabel.TextColor3 = data.hasLuckPass
			and Color3.fromRGB(100, 255, 100)
			or Color3.fromRGB(160, 160, 180)
	end

	-- Get weights with current luck, ceiling, and floor
	local weights = RarityUtil.getEffectiveWeights(luck, ceilingLevel, floorLevel)

	-- Sort by tier ascending
	local sorted = {}
	for tier, prob in pairs(weights) do
		table.insert(sorted, { tier = tier, prob = prob })
	end
	table.sort(sorted, function(a, b)
		return a.tier < b.tier
	end)

	-- Render rows
	for i, entry in ipairs(sorted) do
		local tierInfo = TierData.get(entry.tier)
		local pctStr = string.format("%.2f%%", entry.prob * 100)

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 24)
		row.LayoutOrder = i
		row.BackgroundColor3 = if i % 2 == 0
			then Color3.fromRGB(30, 30, 42)
			else Color3.fromRGB(25, 25, 35)
		row.BackgroundTransparency = 0.3
		row.BorderSizePixel = 0
		row.ZIndex = 11
		row.Parent = scrollFrame

		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

		-- Tier name with color dot
		local tierLabel = Instance.new("TextLabel")
		tierLabel.Size = UDim2.new(0.55, 0, 1, 0)
		tierLabel.Position = UDim2.new(0, 4, 0, 0)
		tierLabel.BackgroundTransparency = 1
		tierLabel.Text = "● " .. tierInfo.displayName
		tierLabel.TextColor3 = tierInfo.color
		tierLabel.TextSize = 12
		tierLabel.Font = Enum.Font.GothamBold
		tierLabel.TextXAlignment = Enum.TextXAlignment.Left
		tierLabel.ZIndex = 11
		tierLabel.Parent = row

		-- Probability
		local probLabel = Instance.new("TextLabel")
		probLabel.Size = UDim2.new(0.4, 0, 1, 0)
		probLabel.Position = UDim2.new(0.58, 0, 0, 0)
		probLabel.BackgroundTransparency = 1
		probLabel.Text = pctStr
		probLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
		probLabel.TextSize = 12
		probLabel.Font = Enum.Font.Gotham
		probLabel.TextXAlignment = Enum.TextXAlignment.Right
		probLabel.ZIndex = 11
		probLabel.Parent = row
	end

	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #sorted * 26)
end

-- Update when data changes or popup becomes visible
local cachedData = nil

dataChangedEvent.Event:Connect(function(data)
	cachedData = data
	if frame.Visible then
		renderOdds(data)
	end
end)

frame:GetPropertyChangedSignal("Visible"):Connect(function()
	if frame.Visible then
		renderOdds(cachedData)
	end
end)

-- Do an initial render with default luck so the popup isn't empty if opened before first sync
renderOdds(nil)

--------------------------------------------------------------------------------
-- Responsive Layout
--------------------------------------------------------------------------------

local function applyScreen(info)
	if info.deviceClass == "Tablet" then
		local innerScale = 1.30 -- ZMĚŇ TOTO ČÍSLO (zvětšení vnitřku)
		uiScale.Scale = info.scale * innerScale
		frame.Size = UDim2.new(0, 360, 0, 400)
	elseif info.deviceClass == "Mobile" then
		local mobileScale = 0.85 -- ZMĚŇ TOTO ČÍSLO (zmenšení celého okna na mobilu)
		uiScale.Scale = info.scale * mobileScale
		frame.Size = UDim2.new(0, 360, 0, 320) -- Speciální snížená výška pro mobil (X nebude pod HUDem)
	else
		local pcScale = 1.15 -- ZMĚŇ TOTO ČÍSLO (celkové zvětšení okna na počítači)
		uiScale.Scale = info.scale * pcScale
		frame.Size = UDim2.new(0, 360, 0, 400)
	end
end

ScreenManager.ScreenChanged:Connect(applyScreen)
if ScreenManager.CurrentClass then
	applyScreen({
		deviceClass = ScreenManager.CurrentClass,
		scale = ScreenManager.CurrentScale
	})
end

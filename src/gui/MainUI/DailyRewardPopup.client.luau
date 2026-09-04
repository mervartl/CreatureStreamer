--[[
	DailyRewardPopup.client.luau — Daily streak reward display and claim button.
	Shows on join if claimable, with streak progress visualization.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local stateFolder = playerGui:WaitForChild("ClientState")
local dataChangedEvent = stateFolder:WaitForChild("DataChanged")
local Remotes = stateFolder:WaitForChild("RemotesRef").Value

local ClaimDailyReward = Remotes:WaitForChild("ClaimDailyReward")

local mainUI = playerGui:WaitForChild("MainUI")

--------------------------------------------------------------------------------
-- Build UI
--------------------------------------------------------------------------------

local frame = Instance.new("Frame")
frame.Name = "DailyRewardFrame"
frame.Size = UDim2.new(0, 320, 0, 220)
frame.Position = UDim2.new(0.5, -160, 0.5, -110)
frame.BackgroundColor3 = Color3.fromRGB(25, 20, 35)
frame.BackgroundTransparency = 0.02
frame.BorderSizePixel = 0
frame.Visible = false  -- shown when claimable
frame.ZIndex = 15
frame.Parent = mainUI

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 32)
title.Position = UDim2.new(0, 0, 0, 8)
title.BackgroundTransparency = 1
title.Text = "🎁 Daily Reward"
title.TextColor3 = Color3.fromRGB(255, 200, 80)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.ZIndex = 16
title.Parent = frame

local streakLabel = Instance.new("TextLabel")
streakLabel.Name = "StreakLabel"
streakLabel.Size = UDim2.new(1, -20, 0, 22)
streakLabel.Position = UDim2.new(0, 10, 0, 42)
streakLabel.BackgroundTransparency = 1
streakLabel.Text = "🔥 Streak: 0 days"
streakLabel.TextColor3 = Color3.fromRGB(255, 150, 50)
streakLabel.TextSize = 14
streakLabel.Font = Enum.Font.GothamBold
streakLabel.TextXAlignment = Enum.TextXAlignment.Left
streakLabel.ZIndex = 16
streakLabel.Parent = frame

-- Day boxes row
local daysRow = Instance.new("Frame")
daysRow.Name = "DaysRow"
daysRow.Size = UDim2.new(1, -20, 0, 60)
daysRow.Position = UDim2.new(0, 10, 0, 70)
daysRow.BackgroundTransparency = 1
daysRow.ZIndex = 16
daysRow.Parent = frame

local dayBoxes = {}
for i = 1, #Config.DAILY_REWARDS do
	local reward = Config.DAILY_REWARDS[i]

	local box = Instance.new("Frame")
	box.Size = UDim2.new(1 / #Config.DAILY_REWARDS, -4, 1, 0)
	box.Position = UDim2.new((i - 1) / #Config.DAILY_REWARDS, 2, 0, 0)
	box.BackgroundColor3 = Color3.fromRGB(40, 35, 55)
	box.BorderSizePixel = 0
	box.ZIndex = 16
	box.Parent = daysRow
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

	local dayLabel = Instance.new("TextLabel")
	dayLabel.Size = UDim2.new(1, 0, 0, 18)
	dayLabel.Position = UDim2.new(0, 0, 0, 4)
	dayLabel.BackgroundTransparency = 1
	dayLabel.Text = "D" .. i
	dayLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
	dayLabel.TextSize = 10
	dayLabel.Font = Enum.Font.GothamBold
	dayLabel.ZIndex = 16
	dayLabel.Parent = box

	local amountLabel = Instance.new("TextLabel")
	amountLabel.Size = UDim2.new(1, 0, 0, 16)
	amountLabel.Position = UDim2.new(0, 0, 0, 22)
	amountLabel.BackgroundTransparency = 1
	amountLabel.Text = "?" -- Updated when data loads
	amountLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	amountLabel.TextSize = 10
	amountLabel.Font = Enum.Font.Gotham
	amountLabel.ZIndex = 16
	amountLabel.Parent = box

	local checkLabel = Instance.new("TextLabel")
	checkLabel.Name = "Check"
	checkLabel.Size = UDim2.new(1, 0, 0, 16)
	checkLabel.Position = UDim2.new(0, 0, 1, -18)
	checkLabel.BackgroundTransparency = 1
	checkLabel.Text = ""
	checkLabel.TextSize = 12
	checkLabel.ZIndex = 16
	checkLabel.Parent = box

	dayBoxes[i] = { frame = box, check = checkLabel, amountLabel = amountLabel }
end

-- Claim button
local claimBtn = Instance.new("TextButton")
claimBtn.Name = "ClaimButton"
claimBtn.Size = UDim2.new(0.6, 0, 0, 40)
claimBtn.Position = UDim2.new(0.2, 0, 0, 140)
claimBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
claimBtn.Text = "🎁 Claim Today's Reward!"
claimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
claimBtn.TextSize = 14
claimBtn.Font = Enum.Font.GothamBold
claimBtn.AutoButtonColor = true
claimBtn.ZIndex = 16
claimBtn.Parent = frame
Instance.new("UICorner", claimBtn).CornerRadius = UDim.new(0, 8)

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -34, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 17
closeBtn.Parent = frame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

closeBtn.MouseButton1Click:Connect(function()
	frame.Visible = false
end)

--------------------------------------------------------------------------------
-- Logic
--------------------------------------------------------------------------------

local debounce = false
local hasShownThisSession = false

claimBtn.MouseButton1Click:Connect(function()
	if debounce then return end
	debounce = true

	claimBtn.Text = "Claiming..."
	ClaimDailyReward:FireServer()

	task.wait(1)
	claimBtn.Text = "✅ Claimed!"
	claimBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)

	task.wait(2)
	frame.Visible = false
	debounce = false
end)

-- Update display
local function updateDisplay(data)
	if not data then return end

	local streak = data.dailyStreak or 0
	streakLabel.Text = "🔥 Streak: " .. streak .. " days"

	-- Calculate total passive income for display
	local totalIncome = 0
	if data.workers then
		for _, worker in ipairs(data.workers) do
			totalIncome = totalIncome + (Config.INCOME_PER_TIER[worker.tier] or 0)
		end
	end

	-- Update day boxes
	local currentDay = (streak % #Config.DAILY_REWARDS)
	for i, dayBox in ipairs(dayBoxes) do
		local rewardConfig = Config.DAILY_REWARDS[i]
		local estimatedReward = rewardConfig.flatBase + (totalIncome * rewardConfig.minutesMultiplier)
		dayBox.amountLabel.Text = tostring(estimatedReward)

		if i <= currentDay then
			dayBox.frame.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
			dayBox.check.Text = "✅"
		elseif i == currentDay + 1 then
			dayBox.frame.BackgroundColor3 = Color3.fromRGB(80, 80, 40)
			dayBox.check.Text = "➡️"
		else
			dayBox.frame.BackgroundColor3 = Color3.fromRGB(40, 35, 55)
			dayBox.check.Text = ""
		end
	end

	-- Check if claimable (compare date)
	local today = os.date("!%Y-%m-%d")
	local canClaim = data.lastDailyClaimDate ~= today

	if canClaim and not hasShownThisSession then
		frame.Visible = true
		hasShownThisSession = true
		claimBtn.Text = "🎁 Claim Today's Reward!"
		claimBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
	end
end

dataChangedEvent.Event:Connect(function(data)
	updateDisplay(data)
end)

-- State Polling on Init
local getStateFunc = stateFolder:WaitForChild("GetState")
local initialData = getStateFunc:Invoke()
if initialData then
	updateDisplay(initialData)
end

--[[
	SessionRewardPopup.client.luau — Displays session timer progress
	and claim buttons for 15/30 min milestones.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local stateFolder = playerGui:WaitForChild("ClientState")
local dataChangedEvent = stateFolder:WaitForChild("DataChanged")
local Remotes = stateFolder:WaitForChild("RemotesRef").Value

local ClaimSessionReward = Remotes:WaitForChild("ClaimSessionReward")

local mainUI = playerGui:WaitForChild("MainUI")
local ScreenManager = require(script.Parent:WaitForChild("ScreenManager"))

--------------------------------------------------------------------------------
-- Build UI
--------------------------------------------------------------------------------

local frame = Instance.new("Frame")
frame.Name = "SessionRewardFrame"
frame.Size = UDim2.new(0, 250, 0, 46)  -- start collapsed
frame.Position = UDim2.new(0, 16, 0, 62)  -- below CurrencyHUD
frame.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
frame.Parent = mainUI

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(280, 440)
sizeConstraint.Parent = frame

local uiScale = Instance.new("UIScale")
uiScale.Scale = 1.0
uiScale.Parent = frame

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.Position = UDim2.new(0, 0, 0, 6)
title.BackgroundTransparency = 1
title.Text = "⏰ Session Rewards"
title.TextColor3 = Color3.fromRGB(200, 180, 255)
title.TextSize = 17
title.Font = Enum.Font.GothamBold
title.Parent = frame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleBtn"
toggleBtn.Size = UDim2.new(0, 24, 0, 24)
toggleBtn.Position = UDim2.new(1, -32, 0, 8)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
toggleBtn.Text = "+"  -- collapsed by default
toggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
toggleBtn.TextSize = 16
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = frame
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 4)

-- Event connection moved down to avoid variable shadowing

local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Size = UDim2.new(1, -20, 0, 18)
timerLabel.Position = UDim2.new(0, 10, 0, 34)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = "Time: 0:00"
timerLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
timerLabel.TextSize = 15
timerLabel.Font = Enum.Font.Gotham
timerLabel.TextXAlignment = Enum.TextXAlignment.Left
timerLabel.Parent = frame

-- Milestone rows
local milestoneFrames = {}

for i, milestone in ipairs(Config.SESSION_MILESTONES) do
	local row = Instance.new("Frame")
	row.Name = "Milestone_" .. i
	row.Size = UDim2.new(1, -20, 0, 38)
	row.Position = UDim2.new(0, 10, 0, 54 + (i - 1) * 44)
	row.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
	row.BorderSizePixel = 0
	row.Parent = frame
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

	local minutes = math.floor(milestone.time / 60)
	local desc = Instance.new("TextLabel")
	desc.Name = "Desc"
	desc.Size = UDim2.new(0.55, 0, 1, 0)
	desc.Position = UDim2.new(0, 8, 0, 0)
	desc.BackgroundTransparency = 1
	desc.Text = minutes .. " min: ..."
	desc.TextColor3 = Color3.fromRGB(200, 200, 220)
	desc.TextSize = 11
	desc.Font = Enum.Font.Gotham
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextWrapped = true
	desc.Parent = row

	local claimBtn = Instance.new("TextButton")
	claimBtn.Name = "ClaimBtn"
	claimBtn.Size = UDim2.new(0.38, 0, 0, 26)
	claimBtn.Position = UDim2.new(0.58, 0, 0.5, -13)
	claimBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
	claimBtn.Text = "⏳ Wait"
	claimBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
	claimBtn.TextSize = 11
	claimBtn.Font = Enum.Font.GothamBold
	claimBtn.AutoButtonColor = true
	claimBtn.Parent = row
	Instance.new("UICorner", claimBtn).CornerRadius = UDim.new(0, 6)

	claimBtn.MouseButton1Click:Connect(function()
		ClaimSessionReward:FireServer(i)
	end)

	milestoneFrames[i] = { row = row, btn = claimBtn, desc = desc }
end

-- Start collapsed by default so it doesn't cover the egg inventory panel
local isCollapsed = true
timerLabel.Visible = false
for _, mf in ipairs(milestoneFrames) do
	mf.row.Visible = false
end

toggleBtn.MouseButton1Click:Connect(function()
	isCollapsed = not isCollapsed
	if isCollapsed then
		frame.Size = UDim2.new(0, 250, 0, 46)
		toggleBtn.Text = "+"
		timerLabel.Visible = false
		for _, mf in ipairs(milestoneFrames) do
			mf.row.Visible = false
		end
	else
		-- Needs enough height for N milestones
		local expandedHeight = 60 + (#Config.SESSION_MILESTONES * 44)
		frame.Size = UDim2.new(0, 250, 0, expandedHeight)
		toggleBtn.Text = "-"
		timerLabel.Visible = true
		for _, mf in ipairs(milestoneFrames) do
			mf.row.Visible = true
		end
	end
end)

--------------------------------------------------------------------------------
-- Update timer and milestone states
--------------------------------------------------------------------------------

local cachedData = nil

dataChangedEvent.Event:Connect(function(data)
	cachedData = data
end)

-- Live timer update loop
task.spawn(function()
	while true do
		task.wait(1)

		if cachedData and cachedData.sessionStartTime then
			local elapsed = os.clock() - cachedData.sessionStartTime
			local minutes = math.floor(elapsed / 60)
			local seconds = math.floor(elapsed % 60)
			timerLabel.Text = string.format("Time: %d:%02d", minutes, seconds)
			
			local incomePerMinute = 0
			if cachedData.workers then
				local ticksPerMinute = 60 / Config.INCOME_TICK_SECONDS
				for _, worker in ipairs(cachedData.workers) do
					incomePerMinute = incomePerMinute + (Config.INCOME_PER_TIER[worker.tier] or 0) * ticksPerMinute
				end
			end

			-- Update milestone buttons
			for i, milestone in ipairs(Config.SESSION_MILESTONES) do
				local mf = milestoneFrames[i]
				if mf then
					local claimed = cachedData.sessionRewardsClaimed and cachedData.sessionRewardsClaimed[i]
					if claimed then
						mf.btn.Text = "✅ Claimed"
						mf.btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
						mf.btn.TextColor3 = Color3.fromRGB(120, 120, 120)
					elseif elapsed >= milestone.time then
						mf.btn.Text = "🎁 Claim!"
						mf.btn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
						mf.btn.TextColor3 = Color3.fromRGB(255, 255, 255)
					else
						local remaining = milestone.time - elapsed
						local remMin = math.floor(remaining / 60)
						local remSec = math.floor(remaining % 60)
						mf.btn.Text = string.format("⏳ %d:%02d", remMin, remSec)
						mf.btn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
						mf.btn.TextColor3 = Color3.fromRGB(180, 180, 180)
					end
					
					local currentReward = (milestone.flatBase or 0) + (incomePerMinute * (milestone.minutesMultiplier or 0))
					local descText = string.format("%d min: %d💰", math.floor(milestone.time / 60), currentReward)
					if milestone.freeEgg then
						descText = descText .. " + 🥚"
					end
					if milestone.luckBoost and milestone.luckBoost > 0 then
						descText = descText .. " + 🍀"
					end
					mf.desc.Text = descText
				end
			end
		end
	end
end)

--------------------------------------------------------------------------------
-- Responsive Layout
--------------------------------------------------------------------------------

local function applyScreen(info)
	uiScale.Scale = info.scale
	if info.deviceClass == "Mobile" then
		frame.Position = UDim2.new(0, 10, 0, 65)
	elseif info.deviceClass == "Tablet" then
		local innerScale = 1.25 -- ZMĚŇ TOTO ČÍSLO (zvětšení vnitřku)
		uiScale.Scale = info.scale * innerScale
		frame.Position = UDim2.new(0, 16, 0, 65)
	else
		frame.Position = UDim2.new(0, 16, 0, 65)
	end
end

ScreenManager.ScreenChanged:Connect(applyScreen)
if ScreenManager.CurrentClass then
	applyScreen({
		deviceClass = ScreenManager.CurrentClass,
		scale = ScreenManager.CurrentScale
	})
end

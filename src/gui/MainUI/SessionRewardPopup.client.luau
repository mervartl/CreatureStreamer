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
	local descContainer = Instance.new("Frame")
	descContainer.Name = "DescContainer"
	descContainer.Size = UDim2.new(0.55, 0, 1, 0)
	descContainer.Position = UDim2.new(0, 8, 0, 0)
	descContainer.BackgroundTransparency = 1
	descContainer.Parent = row

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Horizontal
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 4)
	listLayout.Parent = descContainer

	local desc1 = Instance.new("TextLabel")
	desc1.Name = "Desc1"
	desc1.Size = UDim2.new(0, 0, 1, 0)
	desc1.AutomaticSize = Enum.AutomaticSize.X
	desc1.BackgroundTransparency = 1
	desc1.Text = minutes .. " min: ..."
	desc1.TextColor3 = Color3.fromRGB(200, 200, 220)
	desc1.TextSize = 11
	desc1.Font = Enum.Font.Gotham
	desc1.TextXAlignment = Enum.TextXAlignment.Left
	desc1.LayoutOrder = 1
	desc1.Parent = descContainer

	local icon = Instance.new("ImageLabel")
	icon.Name = "CurrencyIcon"
	icon.Size = UDim2.new(0, 14, 0, 14)
	icon.BackgroundTransparency = 1
	icon.Image = "rbxassetid://140422618178848"
	icon.LayoutOrder = 2
	icon.Parent = descContainer

	local desc2 = Instance.new("TextLabel")
	desc2.Name = "Desc2"
	desc2.Size = UDim2.new(0, 0, 1, 0)
	desc2.AutomaticSize = Enum.AutomaticSize.X
	desc2.BackgroundTransparency = 1
	desc2.Text = ""
	desc2.TextColor3 = Color3.fromRGB(200, 200, 220)
	desc2.TextSize = 11
	desc2.Font = Enum.Font.Gotham
	desc2.TextXAlignment = Enum.TextXAlignment.Left
	desc2.LayoutOrder = 3
	desc2.Parent = descContainer

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

	milestoneFrames[i] = { row = row, btn = claimBtn, desc1 = desc1, desc2 = desc2 }
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

-- State Polling on Init
local getStateFunc = stateFolder:WaitForChild("GetState")
local initialData = getStateFunc:Invoke()
if initialData then
	cachedData = initialData
end

-- Live timer update loop
task.spawn(function()
	while true do
		task.wait(1)

		if cachedData and cachedData.sessionStartTime then
			local elapsed = workspace:GetServerTimeNow() - cachedData.sessionStartTime
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
					mf.desc1.Text = string.format("%d min: %d ", math.floor(milestone.time / 60), currentReward)
					
					local desc2Text = ""
					if milestone.freeEgg then
						desc2Text = desc2Text .. " + 🥚"
					end
					if milestone.luckBoost and milestone.luckBoost > 0 then
						desc2Text = desc2Text .. " + 🍀"
					end
					mf.desc2.Text = desc2Text
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

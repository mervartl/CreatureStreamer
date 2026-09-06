--[[
	JobSlotsScreen.client.luau — Active workers display with sell option.
	Shows workers earning passive income, with per-worker income info.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TierData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TierData"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local stateFolder = playerGui:WaitForChild("ClientState")
local dataChangedEvent = stateFolder:WaitForChild("DataChanged")
local proximityEvent = stateFolder:WaitForChild("PlotProximityChanged")
local Remotes = stateFolder:WaitForChild("RemotesRef").Value

local SellWorker = Remotes:WaitForChild("SellWorker")

local mainUI = playerGui:WaitForChild("MainUI")
local ScreenManager = require(script.Parent:WaitForChild("ScreenManager"))

--------------------------------------------------------------------------------
-- Build UI
--------------------------------------------------------------------------------

local frame = Instance.new("Frame")
frame.Name = "JobSlotsFrame"
frame.Size = UDim2.new(0.92, 0, 0.85, 0)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)  -- perfectly centered
frame.ZIndex = 40
frame.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = mainUI

local frameSizeConstraint = Instance.new("UISizeConstraint")
frameSizeConstraint.MaxSize = Vector2.new(480, 500)
frameSizeConstraint.Parent = frame

local uiScale = Instance.new("UIScale")
uiScale.Scale = 1.0
uiScale.Parent = frame

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 44)
title.Position = UDim2.new(0, 0, 0, 6)
title.BackgroundTransparency = 1
title.Text = "🎙️ Streaming Jobs"
title.TextColor3 = Color3.fromRGB(100, 200, 255)
title.TextSize = 22
title.Font = Enum.Font.GothamBold
title.Parent = frame

local incomeLabel = Instance.new("TextLabel")
incomeLabel.Name = "IncomeLabel"
incomeLabel.Size = UDim2.new(1, -20, 0, 20)
incomeLabel.Position = UDim2.new(0, 10, 0, 46)
incomeLabel.BackgroundTransparency = 1
incomeLabel.Text = "Total Income: 0/min"
incomeLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
incomeLabel.TextSize = 15
incomeLabel.Font = Enum.Font.GothamBold
incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
incomeLabel.Parent = frame

-- Scrolling list for workers
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "WorkerList"
scrollFrame.Size = UDim2.new(1, -20, 1, -90)
scrollFrame.Position = UDim2.new(0, 10, 0, 75)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 5
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollFrame

--------------------------------------------------------------------------------
-- Render workers
--------------------------------------------------------------------------------

local debounce = false
local cachedData = nil
local currentLayout = {
	rowHeight = 72,
	nameSize = 15,
	incSize = 13,
	sellSize = 12,
	emptySize = 15,
	sellBtnHeight = 36,
	sellBtnY = -18
}

local function renderWorkers(data)
	-- Clear existing
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	if not data then
		return
	end

	-- Calculate total income
	local totalIncome = 0
	for _, worker in ipairs(data.workers) do
		totalIncome = totalIncome + (Config.INCOME_PER_TIER[worker.tier] or 0)
	end
	incomeLabel.Text = "Total Income: " .. totalIncome .. "/min"

	-- Render each worker
	for i, worker in ipairs(data.workers) do
		local tierInfo = TierData.get(worker.tier)
		local income = Config.INCOME_PER_TIER[worker.tier] or 0
		local sellValue = Config.SELL_WORKER_VALUE_PER_TIER[worker.tier] or 0

		local row = Instance.new("Frame")
		row.Name = "Worker_" .. worker.id
		row.Size = UDim2.new(1, 0, 0, currentLayout.rowHeight)
		row.LayoutOrder = i
		row.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
		row.BorderSizePixel = 0
		row.Parent = scrollFrame

		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

		-- Color bar on left
		local colorBar = Instance.new("Frame")
		colorBar.Size = UDim2.new(0, 6, 1, -8)
		colorBar.Position = UDim2.new(0, 4, 0, 4)
		colorBar.BackgroundColor3 = tierInfo.color
		colorBar.BorderSizePixel = 0
		colorBar.Parent = row
		Instance.new("UICorner", colorBar).CornerRadius = UDim.new(0, 3)

		-- Name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.6, -16, 0, 24)
		nameLabel.Position = UDim2.new(0, 16, 0, 6)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = tierInfo.displayName
		nameLabel.TextColor3 = tierInfo.color
		nameLabel.TextSize = currentLayout.nameSize
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = row

		-- Income
		local incLabel = Instance.new("TextLabel")
		incLabel.Size = UDim2.new(0.6, -16, 0, 20)
		incLabel.Position = UDim2.new(0, 16, 0, 36)
		incLabel.BackgroundTransparency = 1
		incLabel.Text = "      " .. income .. "/min"
		incLabel.TextColor3 = Color3.fromRGB(140, 200, 140)
		incLabel.TextSize = currentLayout.incSize
		incLabel.Font = Enum.Font.Gotham
		incLabel.TextXAlignment = Enum.TextXAlignment.Left
		incLabel.Parent = row

		local icon = Instance.new("ImageLabel")
		icon.Size = UDim2.new(0, 16, 0, 16)
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.Position = UDim2.new(0, 0, 0.5, 0)
		icon.BackgroundTransparency = 1
		icon.Image = "rbxassetid://140422618178848"
		icon.Parent = incLabel

		-- Sell button
		local sellBtn = Instance.new("TextButton")
		sellBtn.Size = UDim2.new(0.35, 0, 0, currentLayout.sellBtnHeight)
		sellBtn.Position = UDim2.new(0.62, 0, 0.5, currentLayout.sellBtnY)
		sellBtn.BackgroundColor3 = Color3.fromRGB(150, 60, 60)
		sellBtn.Text = "Sell\n" .. sellValue
		sellBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		sellBtn.TextSize = currentLayout.sellSize
		sellBtn.Font = Enum.Font.GothamBold
		sellBtn.AutoButtonColor = true
		sellBtn.Parent = row
		Instance.new("UICorner", sellBtn).CornerRadius = UDim.new(0, 6)

		sellBtn.MouseButton1Click:Connect(function()
			if debounce then return end
			debounce = true

			local success, result = SellWorker:InvokeServer(worker.id)
			if success then
				-- Data will sync automatically
			end

			task.wait(0.3)
			debounce = false
		end)
	end

	-- Show empty slots
	local emptySlots = data.jobSlotsCap - #data.workers
	for j = 1, emptySlots do
		local emptyRow = Instance.new("Frame")
		emptyRow.Name = "EmptySlot_" .. j
		emptyRow.Size = UDim2.new(1, 0, 0, currentLayout.rowHeight)
		emptyRow.LayoutOrder = #data.workers + j
		emptyRow.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
		emptyRow.BackgroundTransparency = 0.3
		emptyRow.BorderSizePixel = 0
		emptyRow.Parent = scrollFrame

		Instance.new("UICorner", emptyRow).CornerRadius = UDim.new(0, 8)

		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 1, 0)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "Empty Slot"
		emptyLabel.TextColor3 = Color3.fromRGB(80, 80, 100)
		emptyLabel.TextSize = currentLayout.emptySize
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.Parent = emptyRow
	end

	-- Update canvas
	local totalRows = data.jobSlotsCap
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalRows * (currentLayout.rowHeight + 6))
end

-- Update when data changes
dataChangedEvent.Event:Connect(function(data, isCurrencyOnly)
	if isCurrencyOnly then return end
	cachedData = data
	renderWorkers(data)
end)

-- State Polling on Init
local getStateFunc = stateFolder:WaitForChild("GetState")
local initialData = getStateFunc:Invoke()
if initialData then
	cachedData = initialData
	renderWorkers(initialData)
end

proximityEvent.Event:Connect(function(isNear)
	-- MobileNavBar handles showing the panel.
	-- We only force-close it when the player leaves the plot.
	if not isNear then
		frame.Visible = false
	end
end)

--------------------------------------------------------------------------------
-- Responsive Layout
--------------------------------------------------------------------------------

local function applyScreen(info)
	uiScale.Scale = info.scale
	local invScale = info.scale > 0 and info.scale or 1

	if info.deviceClass == "Mobile" then
		frame.AnchorPoint = Vector2.new(0.5, 0)
		frame.Position = UDim2.new(0.5, 0, 0, 65 / invScale)
		frame.Size = UDim2.new(0.96 / invScale, 0, 1 / invScale, -110 / invScale)
		
		currentLayout = {
			rowHeight = 72,
			nameSize = 15,
			incSize = 13,
			sellSize = 12,
			emptySize = 15,
			sellBtnHeight = 36,
			sellBtnY = -18
		}
	elseif info.deviceClass == "Tablet" then
		uiScale.Scale = info.scale * 1.08 -- 8% zvětšení okna
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.new(0.5, 0, 0.5, 0)
		frame.Size = UDim2.new(0.92, 0, 0.85, 0)
		
		currentLayout = {
			rowHeight = 90,
			nameSize = 18,
			incSize = 16,
			sellSize = 15,
			emptySize = 18,
			sellBtnHeight = 46,
			sellBtnY = -23
		}
	else
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.new(0.5, 0, 0.5, 0)
		frame.Size = UDim2.new(0.90, 0, 0.85, 0)
		
		currentLayout = {
			rowHeight = 72,
			nameSize = 15,
			incSize = 13,
			sellSize = 12,
			emptySize = 15,
			sellBtnHeight = 36,
			sellBtnY = -18
		}
	end
	
	if cachedData and frame.Visible then
		renderWorkers(cachedData)
	end
end

ScreenManager.ScreenChanged:Connect(applyScreen)
if ScreenManager.CurrentClass then
	applyScreen({
		deviceClass = ScreenManager.CurrentClass,
		scale = ScreenManager.CurrentScale
	})
end

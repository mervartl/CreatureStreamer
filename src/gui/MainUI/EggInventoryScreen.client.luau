--[[
	EggInventoryScreen.client.luau — Displays the mergeable egg pool.
	Shows a grid of eggs color-coded by tier, with merge and sell actions.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TierData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TierData"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local stateFolder = playerGui:WaitForChild("ClientState")
local dataChangedEvent = stateFolder:WaitForChild("DataChanged")
local Remotes = stateFolder:WaitForChild("RemotesRef").Value

local MergeEggs = Remotes:WaitForChild("MergeEggs")
local SellEgg = Remotes:WaitForChild("SellEgg")
local AssignEggToJob = Remotes:WaitForChild("AssignEggToJob")

local mainUI = playerGui:WaitForChild("MainUI")

--------------------------------------------------------------------------------
-- Build UI
--------------------------------------------------------------------------------

local frame = Instance.new("Frame")
frame.Name = "EggInventoryFrame"
frame.Size = UDim2.new(0, 360, 0, 420)
frame.Position = UDim2.new(0.5, -180, 0.5, -210)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.Parent = mainUI

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 36)
title.Position = UDim2.new(0, 0, 0, 6)
title.BackgroundTransparency = 1
title.Text = "🥚 Egg Inventory"
title.TextColor3 = Color3.fromRGB(255, 220, 80)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.Parent = frame

local infoLabel = Instance.new("TextLabel")
infoLabel.Name = "InfoLabel"
infoLabel.Size = UDim2.new(1, -20, 0, 20)
infoLabel.Position = UDim2.new(0, 10, 0, 40)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Select two same-tier eggs to merge"
infoLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
infoLabel.TextSize = 12
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.Parent = frame

-- Scrolling grid for eggs
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "EggGrid"
scrollFrame.Size = UDim2.new(1, -20, 1, -130)
scrollFrame.Position = UDim2.new(0, 10, 0, 65)
scrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
scrollFrame.BackgroundTransparency = 0.5
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent = frame

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 8)
scrollCorner.Parent = scrollFrame

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 60, 0, 70)
gridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = scrollFrame

local gridPadding = Instance.new("UIPadding")
gridPadding.PaddingLeft = UDim.new(0, 6)
gridPadding.PaddingTop = UDim.new(0, 6)
gridPadding.Parent = scrollFrame

-- Action buttons row
local actionRow = Instance.new("Frame")
actionRow.Name = "ActionRow"
actionRow.Size = UDim2.new(1, -20, 0, 36)
actionRow.Position = UDim2.new(0, 10, 1, -55)
actionRow.BackgroundTransparency = 1
actionRow.Parent = frame

local mergeBtn = Instance.new("TextButton")
mergeBtn.Name = "MergeButton"
mergeBtn.Size = UDim2.new(0.32, 0, 1, 0)
mergeBtn.Position = UDim2.new(0, 0, 0, 0)
mergeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
mergeBtn.Text = "🔄 Merge"
mergeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
mergeBtn.TextSize = 13
mergeBtn.Font = Enum.Font.GothamBold
mergeBtn.AutoButtonColor = true
mergeBtn.Parent = actionRow
Instance.new("UICorner", mergeBtn).CornerRadius = UDim.new(0, 6)

local sellBtn = Instance.new("TextButton")
sellBtn.Name = "SellButton"
sellBtn.Size = UDim2.new(0.32, 0, 1, 0)
sellBtn.Position = UDim2.new(0.34, 0, 0, 0)
sellBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 80)
sellBtn.Text = "💰 Sell"
sellBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sellBtn.TextSize = 13
sellBtn.Font = Enum.Font.GothamBold
sellBtn.AutoButtonColor = true
sellBtn.Parent = actionRow
Instance.new("UICorner", sellBtn).CornerRadius = UDim.new(0, 6)

local assignBtn = Instance.new("TextButton")
assignBtn.Name = "AssignButton"
assignBtn.Size = UDim2.new(0.32, 0, 1, 0)
assignBtn.Position = UDim2.new(0.68, 0, 0, 0)
assignBtn.BackgroundColor3 = Color3.fromRGB(80, 120, 180)
assignBtn.Text = "📺 Assign"
assignBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
assignBtn.TextSize = 13
assignBtn.Font = Enum.Font.GothamBold
assignBtn.AutoButtonColor = true
assignBtn.Parent = actionRow
Instance.new("UICorner", assignBtn).CornerRadius = UDim.new(0, 6)

--------------------------------------------------------------------------------
-- Selection logic
--------------------------------------------------------------------------------

local selectedEggs = {}  -- array of egg IDs (max 2 for merge, 1 for sell/assign)
local eggButtons = {}     -- map of eggId -> button reference

local function clearSelection()
	for _, btn in pairs(eggButtons) do
		local overlay = btn:FindFirstChild("SelectionOverlay")
		if overlay then overlay.Visible = false end
	end
	selectedEggs = {}
	infoLabel.Text = "Select two same-tier eggs to merge"
	infoLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
end

local function updateButtonStates()
	local selCount = #selectedEggs
	mergeBtn.BackgroundColor3 = if selCount == 2
		then Color3.fromRGB(80, 180, 80)
		else Color3.fromRGB(100, 100, 120)
	sellBtn.BackgroundColor3 = if selCount >= 1
		then Color3.fromRGB(180, 80, 80)
		else Color3.fromRGB(100, 100, 120)
	assignBtn.BackgroundColor3 = if selCount == 1
		then Color3.fromRGB(80, 120, 180)
		else Color3.fromRGB(100, 100, 120)
end

local function toggleSelect(eggId: string)
	-- Check if already selected
	for i, id in ipairs(selectedEggs) do
		if id == eggId then
			table.remove(selectedEggs, i)
			if eggButtons[eggId] then
				local overlay = eggButtons[eggId]:FindFirstChild("SelectionOverlay")
				if overlay then overlay.Visible = false end
			end
			updateButtonStates()
			return
		end
	end

	-- Add to selection (max 2)
	if #selectedEggs >= 2 then
		-- Deselect the first one
		local oldId = table.remove(selectedEggs, 1)
		if eggButtons[oldId] then
			local overlay = eggButtons[oldId]:FindFirstChild("SelectionOverlay")
			if overlay then overlay.Visible = false end
		end
	end

	table.insert(selectedEggs, eggId)
	if eggButtons[eggId] then
		local overlay = eggButtons[eggId]:FindFirstChild("SelectionOverlay")
		if overlay then overlay.Visible = true end
	end
	updateButtonStates()
end

--------------------------------------------------------------------------------
-- Render eggs
--------------------------------------------------------------------------------

local function renderEggs(data)
	-- Clear existing
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	eggButtons = {}
	selectedEggs = {}

	if not data or not data.eggs then
		return
	end

	-- Sort eggs by tier (descending) for better visibility
	local sorted = {}
	for _, egg in ipairs(data.eggs) do
		table.insert(sorted, egg)
	end
	table.sort(sorted, function(a, b)
		return a.tier > b.tier
	end)

	for i, egg in ipairs(sorted) do
		local tierInfo = TierData.get(egg.tier)

		local btn = Instance.new("TextButton")
		btn.Name = "Egg_" .. egg.id
		btn.LayoutOrder = i
		btn.BackgroundColor3 = tierInfo.color
		btn.Text = "T" .. egg.tier .. "\n" .. tierInfo.rarityName:sub(1, 3)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextSize = 11
		btn.Font = Enum.Font.GothamBold
		btn.TextWrapped = true
		btn.AutoButtonColor = true
		btn.BorderSizePixel = 0
		btn.Parent = scrollFrame

		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

		local overlay = Instance.new("Frame")
		overlay.Name = "SelectionOverlay"
		overlay.Size = UDim2.new(1, 0, 1, 0)
		overlay.BackgroundColor3 = Color3.fromRGB(255, 255, 100)
		overlay.BackgroundTransparency = 0.6
		overlay.BorderSizePixel = 0
		overlay.Visible = false
		overlay.Parent = btn
		Instance.new("UICorner", overlay).CornerRadius = UDim.new(0, 8)

		eggButtons[egg.id] = btn

		btn.MouseButton1Click:Connect(function()
			toggleSelect(egg.id)
		end)
	end

	-- Update canvas size
	local rows = math.ceil(#sorted / 5)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, rows * 76 + 12)

	updateButtonStates()
end

--------------------------------------------------------------------------------
-- Action handlers
--------------------------------------------------------------------------------

local debounce = false

mergeBtn.MouseButton1Click:Connect(function()
	if debounce or #selectedEggs < 2 then return end
	debounce = true

	infoLabel.Text = "Merging..."
	local success, result = MergeEggs:InvokeServer(selectedEggs[1], selectedEggs[2])

	if success then
		local tierInfo = TierData.get(result.tier)
		infoLabel.Text = "✨ Merged into " .. tierInfo.displayName .. "!"
		infoLabel.TextColor3 = tierInfo.color
		clearSelection()
	else
		infoLabel.Text = "❌ " .. tostring(result)
		infoLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		clearSelection()
	end

	task.wait(0.3)
	debounce = false
end)

sellBtn.MouseButton1Click:Connect(function()
	if debounce or #selectedEggs < 1 then return end
	debounce = true

	local eggId = selectedEggs[1]
	infoLabel.Text = "Selling..."
	local success, result = SellEgg:InvokeServer(eggId)

	if success then
		infoLabel.Text = "💰 Sold for " .. tostring(result) .. " Viewers!"
		infoLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		clearSelection()
	else
		infoLabel.Text = "❌ " .. tostring(result)
		infoLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		clearSelection()
	end

	task.wait(0.3)
	debounce = false
end)

assignBtn.MouseButton1Click:Connect(function()
	if debounce or #selectedEggs ~= 1 then return end
	debounce = true

	local eggId = selectedEggs[1]

	-- Confirmation prompt (irreversible action)
	infoLabel.Text = "⚠️ Assign is PERMANENT! Click again to confirm."
	infoLabel.TextColor3 = Color3.fromRGB(255, 200, 80)

	-- Wait for second click or timeout
	local confirmed = false
	local conn
	conn = assignBtn.MouseButton1Click:Once(function()
		confirmed = true
	end)

	task.wait(3)
	if conn then
		conn:Disconnect()
	end

	if confirmed then
		infoLabel.Text = "Assigning to job..."
		local success, result = AssignEggToJob:InvokeServer(eggId)
		if success then
			infoLabel.Text = "📺 Assigned to streaming job!"
			infoLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
			clearSelection()
		else
			infoLabel.Text = "❌ " .. tostring(result)
			infoLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			clearSelection()
		end
	else
		infoLabel.Text = "Assignment cancelled."
		infoLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
		clearSelection()
	end

	task.wait(0.3)
	debounce = false
end)

-- Update when data changes
dataChangedEvent.Event:Connect(function(data)
	renderEggs(data)
end)

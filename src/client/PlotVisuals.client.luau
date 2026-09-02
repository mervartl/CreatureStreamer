--[[
	PlotVisuals.client.luau
	Manages purely client-side visuals for the player's plot, such as
	hiding unpurchased job slots and displaying a "Locked" purchase GUI.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local stateFolder = playerGui:WaitForChild("ClientState")
local dataChangedEvent = stateFolder:WaitForChild("DataChanged")
local Remotes = stateFolder:WaitForChild("RemotesRef").Value
local BuySlot = Remotes:WaitForChild("BuySlot")

local debounce = false

local function updatePlotVisuals(data)
	if not data then return end
	
	local plotName = player.Name .. "_Plot"
	local plot = Workspace:FindFirstChild(plotName)
	if not plot then return end
	
	for i = 1, Config.JOB_SLOTS_MAX do
		local slot = plot:FindFirstChild("JobSlot" .. i)
		if not slot then continue end
		
		-- Clear old indicators
		local oldGui = playerGui:FindFirstChild("LockedIndicator_" .. i)
		if oldGui then oldGui:Destroy() end
		
		if i <= data.jobSlotsCap then
			-- Slot is owned
			slot.Transparency = 0
		else
			-- Slot is locked
			slot.Transparency = 1
			
			-- If it's exactly the NEXT slot, show the buy prompt
			if i == data.jobSlotsCap + 1 then
				local slotsBought = data.jobSlotsCap - Config.JOB_SLOTS_INITIAL
				local price = math.floor(Config.JOB_SLOT_BASE_COST * (Config.JOB_SLOT_COST_SCALE ^ slotsBought))
				
				local billboard = Instance.new("BillboardGui")
				billboard.Name = "LockedIndicator_" .. i
				billboard.Size = UDim2.new(0, 150, 0, 45)
				billboard.StudsOffset = Vector3.new(0, 2, 0)
				billboard.AlwaysOnTop = true
				billboard.Adornee = slot
				
				local textBtn = Instance.new("TextButton")
				textBtn.Size = UDim2.new(1, 0, 1, 0)
				textBtn.BackgroundTransparency = 0.2
				textBtn.BackgroundColor3 = Color3.fromRGB(30, 25, 40)
				textBtn.Text = "🔒 Locked\nBuy for " .. price .. " 👁"
				textBtn.TextColor3 = Color3.fromRGB(255, 200, 80)
				textBtn.TextSize = 13
				textBtn.Font = Enum.Font.GothamBold
				textBtn.Parent = billboard
				
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, 6)
				corner.Parent = textBtn
				
				billboard.Parent = playerGui
				
				textBtn.MouseButton1Click:Connect(function()
					if debounce then return end
					debounce = true
					
					textBtn.Text = "Purchasing..."
					local success, result = BuySlot:InvokeServer("job")
					if not success then
						textBtn.Text = "❌ " .. tostring(result)
						task.wait(1)
						-- Update with default text
						textBtn.Text = "🔒 Locked\nBuy for " .. price .. " 👁"
					end
					
					debounce = false
				end)
			end
		end
	end
end

-- We keep the most recent data here
local cachedData = nil

dataChangedEvent.Event:Connect(function(data)
	cachedData = data
	updatePlotVisuals(data)
end)

-- Because the plot might take a second to spawn when the player joins,
-- we check periodically until it exists, then do an initial render.
task.spawn(function()
	local plotName = player.Name .. "_Plot"
	Workspace:WaitForChild(plotName, 60)
	
	-- Once plot exists, wait a short moment for possible data syncs
	task.wait(0.5)
	if cachedData then
		updatePlotVisuals(cachedData)
	end
end)

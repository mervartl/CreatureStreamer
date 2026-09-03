--[[
	ShopScreen.client.luau — Slot expansions, Game Pass, and Developer Products.
	Toggleable panel with buy buttons for each shop item.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local stateFolder = playerGui:WaitForChild("ClientState")
local dataChangedEvent = stateFolder:WaitForChild("DataChanged")
local Remotes = stateFolder:WaitForChild("RemotesRef").Value

local BuySlot = Remotes:WaitForChild("BuySlot")

local mainUI = playerGui:WaitForChild("MainUI")
local ScreenManager = require(script.Parent:WaitForChild("ScreenManager"))

--------------------------------------------------------------------------------
-- Build UI
--------------------------------------------------------------------------------

local frame = Instance.new("Frame")
frame.Name = "ShopFrame"
frame.Size = UDim2.new(0, 280, 0, 380)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, 0) -- perfectly centered on all screens
frame.BackgroundColor3 = Color3.fromRGB(30, 25, 40)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.Visible = false -- toggled by MobileNavBar Shop button
frame.Parent = mainUI

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local frameScale = Instance.new("UIScale")
frameScale.Scale = 1.0
frameScale.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 36)
title.Position = UDim2.new(0, 0, 0, 6)
title.BackgroundTransparency = 1
title.Text = "🛒 Shop"
title.TextColor3 = Color3.fromRGB(255, 200, 80)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.Parent = frame

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -36, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = frame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

closeBtn.MouseButton1Click:Connect(function()
	frame.Visible = false
end)

-- Content list
local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Size = UDim2.new(1, -20, 1, -50)
contentFrame.Position = UDim2.new(0, 10, 0, 46)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 5
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 400)
contentFrame.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = contentFrame

--------------------------------------------------------------------------------
-- Helper: create a shop item row
--------------------------------------------------------------------------------

local function createShopItem(parent, order, titleText, descText, btnText, btnColor, onClick)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 66)
	row.LayoutOrder = order
	row.BackgroundColor3 = Color3.fromRGB(40, 35, 55)
	row.BorderSizePixel = 0
	row.Parent = parent
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

	local itemTitle = Instance.new("TextLabel")
	itemTitle.Size = UDim2.new(0.6, 0, 0, 22)
	itemTitle.Position = UDim2.new(0, 10, 0, 6)
	itemTitle.BackgroundTransparency = 1
	itemTitle.Text = titleText
	itemTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	itemTitle.TextSize = 14
	itemTitle.Font = Enum.Font.GothamBold
	itemTitle.TextXAlignment = Enum.TextXAlignment.Left
	itemTitle.Parent = row

	local desc = Instance.new("TextLabel")
	desc.Name = "Desc"
	desc.Size = UDim2.new(0.6, 0, 0, 16)
	desc.Position = UDim2.new(0, 10, 0, 28)
	desc.BackgroundTransparency = 1
	desc.Text = descText
	desc.TextColor3 = Color3.fromRGB(160, 160, 180)
	desc.TextSize = 11
	desc.Font = Enum.Font.Gotham
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextWrapped = true
	desc.Parent = row

	local btn = Instance.new("TextButton")
	btn.Name = "BuyButton"
	btn.Size = UDim2.new(0.32, 0, 0, 36)
	btn.Position = UDim2.new(0.65, 0, 0.5, -18)
	btn.BackgroundColor3 = btnColor
	btn.Text = btnText
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 12
	btn.Font = Enum.Font.GothamBold
	btn.AutoButtonColor = true
	btn.Parent = row
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

	btn.MouseButton1Click:Connect(onClick)

	return row
end

--------------------------------------------------------------------------------
-- Shop items
--------------------------------------------------------------------------------

local debounce = false

-- 1. Egg Slot Expansion
local eggSlotRow = createShopItem(
	contentFrame,
	1,
	"🥚 +1 Egg Slot",
	"Expand egg inventory",
	"Buy",
	Color3.fromRGB(80, 150, 80),
	function()
		if debounce then
			return
		end
		debounce = true
		BuySlot:InvokeServer("egg")
		task.wait(0.5)
		debounce = false
	end
)

-- 2. Job Slot Expansion
local jobSlotRow = createShopItem(
	contentFrame,
	2,
	"📺 +1 Job Slot",
	"Expand streaming jobs",
	"Buy",
	Color3.fromRGB(80, 120, 180),
	function()
		if debounce then
			return
		end
		debounce = true
		BuySlot:InvokeServer("job")
		task.wait(0.5)
		debounce = false
	end
)

-- 3. 2x Luck Game Pass
createShopItem(
	contentFrame,
	3,
	"🍀 2x Luck (Permanent)",
	"Doubles hatch odds for rarer eggs",
	"R$ Buy",
	Color3.fromRGB(200, 160, 40),
	function()
		if Config.LUCK_GAMEPASS_ID ~= 0 then
			MarketplaceService:PromptGamePassPurchase(player, Config.LUCK_GAMEPASS_ID)
		else
			warn("[Shop] Luck Game Pass ID not configured!")
		end
	end
)

-- 4. Viewers Pack (Dev Product)
createShopItem(
	contentFrame,
	4,
	"💰 Viewers Pack",
	Config.VIEWERS_PACK_AMOUNT .. " Viewers instantly",
	"R$ Buy",
	Color3.fromRGB(100, 180, 60),
	function()
		if Config.VIEWERS_PACK_PRODUCT_ID ~= 0 then
			MarketplaceService:PromptProductPurchase(player, Config.VIEWERS_PACK_PRODUCT_ID)
		else
			warn("[Shop] Viewers Pack Product ID not configured!")
		end
	end
)

-- 5. Instant Claim (Dev Product)
createShopItem(
	contentFrame,
	5,
	"⏩ Instant Claim",
	"Skip session timer, claim rewards now",
	"R$ Buy",
	Color3.fromRGB(140, 80, 200),
	function()
		if Config.INSTANT_CLAIM_PRODUCT_ID ~= 0 then
			MarketplaceService:PromptProductPurchase(player, Config.INSTANT_CLAIM_PRODUCT_ID)
		else
			warn("[Shop] Instant Claim Product ID not configured!")
		end
	end
)

--------------------------------------------------------------------------------
-- Update slot costs dynamically
--------------------------------------------------------------------------------

local function updateCosts(data)
	if not data then
		return
	end

	-- Egg slot cost
	local eggSlotsBought = data.eggSlotsCap - Config.EGG_SLOTS_INITIAL
	local eggCost = math.floor(Config.EGG_SLOT_BASE_COST * (Config.EGG_SLOT_COST_SCALE ^ eggSlotsBought))
	local eggDesc = eggSlotRow:FindFirstChild("Desc")
	local eggBtn = eggSlotRow:FindFirstChild("BuyButton")
	if eggDesc then
		eggDesc.Text = "Slots: " .. data.eggSlotsCap .. "/" .. Config.EGG_SLOTS_MAX
	end
	if eggBtn then
		if data.eggSlotsCap >= Config.EGG_SLOTS_MAX then
			eggBtn.Text = "MAX"
			eggBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		else
			eggBtn.Text = eggCost .. " 👁"
		end
	end

	-- Job slot cost
	local jobSlotsBought = data.jobSlotsCap - Config.JOB_SLOTS_INITIAL
	local jobCost = math.floor(Config.JOB_SLOT_BASE_COST * (Config.JOB_SLOT_COST_SCALE ^ jobSlotsBought))
	local jobDesc = jobSlotRow:FindFirstChild("Desc")
	local jobBtn = jobSlotRow:FindFirstChild("BuyButton")
	if jobDesc then
		jobDesc.Text = "Slots: " .. data.jobSlotsCap .. "/" .. Config.JOB_SLOTS_MAX
	end
	if jobBtn then
		if data.jobSlotsCap >= Config.JOB_SLOTS_MAX then
			jobBtn.Text = "MAX"
			jobBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		else
			jobBtn.Text = jobCost .. " 👁"
		end
	end
end

dataChangedEvent.Event:Connect(function(data)
	updateCosts(data)
end)

-- Always-visible shop toggle button in the top-right corner
local shopToggle = Instance.new("TextButton")
shopToggle.Name = "ShopToggle"
shopToggle.Size = UDim2.new(0, 64, 0, 44)
shopToggle.AnchorPoint = Vector2.new(1, 0)
shopToggle.Position = UDim2.new(1, -16, 0, 16)
shopToggle.BackgroundColor3 = Color3.fromRGB(200, 160, 40)
shopToggle.Text = "🛒"
shopToggle.TextSize = 24
shopToggle.Font = Enum.Font.GothamBold
shopToggle.AutoButtonColor = true
shopToggle.ZIndex = 20
shopToggle.Parent = mainUI

local uiScale = Instance.new("UIScale")
uiScale.Scale = 1.0
uiScale.Parent = shopToggle
Instance.new("UICorner", shopToggle).CornerRadius = UDim.new(0, 8)

shopToggle.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
end)

--------------------------------------------------------------------------------
-- Responsive Layout
--------------------------------------------------------------------------------

local function applyScreen(info)
	if info.deviceClass == "Mobile" then
		uiScale.Scale = info.scale
		shopToggle.Position = UDim2.new(1, -10, 0, 10)

		local mobileScale = 0.85 -- ZMĚŇ TOTO ČÍSLO (zmenšení celého okna na mobilu)
		frameScale.Scale = info.scale * mobileScale
		frame.Size = UDim2.new(0, 280, 0, 300) -- Speciální snížená výška pro mobil
	elseif info.deviceClass == "Tablet" then
		uiScale.Scale = info.scale * 1.15
		shopToggle.Position = UDim2.new(1, -16, 0, 16)
		local tabletScale = 1.2 -- ZMĚŇ TOTO ČÍSLO (celkové zvětšení okna shopu na tabletu)
		frameScale.Scale = info.scale * tabletScale
		frame.Size = UDim2.new(0, 280, 0, 380)
	else
		uiScale.Scale = info.scale * 1.25
		shopToggle.Position = UDim2.new(1, -20, 0, 20)
		local pcScale = 1.15 -- ZMĚŇ TOTO ČÍSLO (celkové zvětšení okna shopu na počítači)
		frameScale.Scale = info.scale * pcScale
		frame.Size = UDim2.new(0, 280, 0, 380)
	end
end

ScreenManager.ScreenChanged:Connect(applyScreen)
if ScreenManager.CurrentClass then
	applyScreen({
		deviceClass = ScreenManager.CurrentClass,
		scale = ScreenManager.CurrentScale,
	})
end

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
local BuyUpgrade = Remotes:WaitForChild("BuyUpgrade")

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

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
end)

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

	local icon = Instance.new("ImageLabel")
	icon.Name = "CurrencyIcon"
	icon.Size = UDim2.new(0, 16, 0, 16)
	icon.AnchorPoint = Vector2.new(1, 0.5)
	icon.Position = UDim2.new(1, -6, 0.5, 0)
	icon.BackgroundTransparency = 1
	icon.Image = "rbxassetid://140422618178848"
	icon.Visible = false -- Will be turned on by updateCosts if not MAX
	icon.Parent = btn

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
	"🎙️ +1 Job Slot",
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

-- 3. Ceiling Upgrade
local ceilingUpgradeRow = createShopItem(
	contentFrame,
	3,
	"⬆️ Ceiling Upgrade",
	"Unlock higher tiers from hatching",
	"Buy",
	Color3.fromRGB(150, 80, 150),
	function()
		if debounce then return end
		debounce = true
		BuyUpgrade:InvokeServer("ceiling")
		task.wait(0.5)
		debounce = false
	end
)

-- 4. Floor Upgrade
local floorUpgradeRow = createShopItem(
	contentFrame,
	4,
	"⬇️ Floor Upgrade",
	"Remove lowest tier from hatching",
	"Buy",
	Color3.fromRGB(150, 80, 80),
	function()
		if debounce then return end
		debounce = true
		BuyUpgrade:InvokeServer("floor")
		task.wait(0.5)
		debounce = false
	end
)

local function setRobuxPrice(btn, id, infoType)
	if not btn or not id or id == 0 then return end
	task.spawn(function()
		local success, info = pcall(function()
			return MarketplaceService:GetProductInfo(id, infoType)
		end)
		if success and info and info.PriceInRobux then
			btn.Text = "R$ " .. tostring(info.PriceInRobux)
		end
	end)
end

-- 5. 2x Luck Game Pass
local luckPassRow = createShopItem(
	contentFrame,
	5,
	"🍀 2x Luck (Permanent)",
	"Doubles hatch odds for rarer eggs",
	"R$ ...",
	Color3.fromRGB(200, 160, 40),
	function()
		if Config.LUCK_GAMEPASS_ID ~= 0 then
			MarketplaceService:PromptGamePassPurchase(player, Config.LUCK_GAMEPASS_ID)
		else
			warn("[Shop] Luck Game Pass ID not configured!")
		end
	end
)
setRobuxPrice(luckPassRow:FindFirstChild("BuyButton"), Config.LUCK_GAMEPASS_ID, Enum.InfoType.GamePass)

-- 6. Small Viewers Pack
local smallPackRow = createShopItem(
	contentFrame,
	6,
	"💰 Small Viewers Pack",
	Config.VIEWERS_PACK_PRODUCTS.Small.amount .. " Viewers instantly",
	"R$ ...",
	Color3.fromRGB(100, 180, 60),
	function()
		local id = Config.VIEWERS_PACK_PRODUCTS.Small.id
		if id ~= 0 then
			MarketplaceService:PromptProductPurchase(player, id)
		else
			warn("[Shop] Small Viewers Pack ID not configured!")
		end
	end
)
setRobuxPrice(smallPackRow:FindFirstChild("BuyButton"), Config.VIEWERS_PACK_PRODUCTS.Small.id, Enum.InfoType.Product)

-- 7. Medium Viewers Pack
local mediumPackRow = createShopItem(
	contentFrame,
	7,
	"💰 Medium Viewers Pack",
	Config.VIEWERS_PACK_PRODUCTS.Medium.amount .. " Viewers instantly",
	"R$ ...",
	Color3.fromRGB(110, 190, 70),
	function()
		local id = Config.VIEWERS_PACK_PRODUCTS.Medium.id
		if id ~= 0 then
			MarketplaceService:PromptProductPurchase(player, id)
		else
			warn("[Shop] Medium Viewers Pack ID not configured!")
		end
	end
)
setRobuxPrice(mediumPackRow:FindFirstChild("BuyButton"), Config.VIEWERS_PACK_PRODUCTS.Medium.id, Enum.InfoType.Product)

-- 8. Mega Viewers Pack
local megaPackRow = createShopItem(
	contentFrame,
	8,
	"💎 Mega Viewers Pack",
	Config.VIEWERS_PACK_PRODUCTS.Mega.amount .. " Viewers instantly",
	"R$ ...",
	Color3.fromRGB(120, 200, 80),
	function()
		local id = Config.VIEWERS_PACK_PRODUCTS.Mega.id
		if id ~= 0 then
			MarketplaceService:PromptProductPurchase(player, id)
		else
			warn("[Shop] Mega Viewers Pack ID not configured!")
		end
	end
)
setRobuxPrice(megaPackRow:FindFirstChild("BuyButton"), Config.VIEWERS_PACK_PRODUCTS.Mega.id, Enum.InfoType.Product)

-- 9. Instant Claim (Dev Product)
local instantClaimRow = createShopItem(
	contentFrame,
	9,
	"⏩ Instant Claim",
	"Skip session timer, claim rewards now",
	"R$ ...",
	Color3.fromRGB(140, 80, 200),
	function()
		if Config.INSTANT_CLAIM_PRODUCT_ID ~= 0 then
			MarketplaceService:PromptProductPurchase(player, Config.INSTANT_CLAIM_PRODUCT_ID)
		else
			warn("[Shop] Instant Claim Product ID not configured!")
		end
	end
)
setRobuxPrice(instantClaimRow:FindFirstChild("BuyButton"), Config.INSTANT_CLAIM_PRODUCT_ID, Enum.InfoType.Product)

--------------------------------------------------------------------------------
-- Update slot costs dynamically
--------------------------------------------------------------------------------

local function updateCosts(data)
	if not data then
		return
	end

	-- Egg slot cost
	local eggSlotsBought = data.eggSlotsCap - Config.EGG_SLOTS_INITIAL
	local rawEggCost = Config.EGG_SLOT_BASE_COST * (Config.EGG_SLOT_COST_SCALE ^ eggSlotsBought)
	local eggCost = math.floor(rawEggCost / 100 + 0.5) * 100
	local eggDesc = eggSlotRow:FindFirstChild("Desc")
	local eggBtn = eggSlotRow:FindFirstChild("BuyButton")
	if eggDesc then
		eggDesc.Text = "Slots: " .. data.eggSlotsCap .. "/" .. Config.EGG_SLOTS_MAX
	end
	if eggBtn then
		if data.eggSlotsCap >= Config.EGG_SLOTS_MAX then
			eggBtn.Text = "MAX"
			eggBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			if eggBtn:FindFirstChild("CurrencyIcon") then eggBtn.CurrencyIcon.Visible = false end
		else
			eggBtn.Text = tostring(eggCost) .. "    "
			if eggBtn:FindFirstChild("CurrencyIcon") then eggBtn.CurrencyIcon.Visible = true end
		end
	end

	-- Job slot cost
	local jobSlotsBought = data.jobSlotsCap - Config.JOB_SLOTS_INITIAL
	local rawJobCost = Config.JOB_SLOT_BASE_COST * (Config.JOB_SLOT_COST_SCALE ^ jobSlotsBought)
	local jobCost = math.floor(rawJobCost / 100 + 0.5) * 100
	local jobDesc = jobSlotRow:FindFirstChild("Desc")
	local jobBtn = jobSlotRow:FindFirstChild("BuyButton")
	if jobDesc then
		jobDesc.Text = "Slots: " .. data.jobSlotsCap .. "/" .. Config.JOB_SLOTS_MAX
	end
	if jobBtn then
		if data.jobSlotsCap >= Config.JOB_SLOTS_MAX then
			jobBtn.Text = "MAX"
			jobBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			if jobBtn:FindFirstChild("CurrencyIcon") then jobBtn.CurrencyIcon.Visible = false end
		else
			jobBtn.Text = tostring(jobCost) .. "    "
			if jobBtn:FindFirstChild("CurrencyIcon") then jobBtn.CurrencyIcon.Visible = true end
		end
	end
	-- Ceiling Upgrade cost
	local ceilingDesc = ceilingUpgradeRow:FindFirstChild("Desc")
	local ceilingBtn = ceilingUpgradeRow:FindFirstChild("BuyButton")
	local currentMaxTier = Config.BASE_MAX_HATCH_TIER + (data.ceilingLevel or 0)
	
	if currentMaxTier >= Config.TIER_MAX then
		if ceilingDesc then ceilingDesc.Text = "Max ceiling reached" end
		if ceilingBtn then
			ceilingBtn.Text = "MAX"
			ceilingBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		end
	else
		local ceilingCost = Config.getCumulativeMergeCost(currentMaxTier) * Config.CEILING_UPGRADE_MULTIPLIER
		if ceilingDesc then ceilingDesc.Text = "Max Tier: +" .. (data.ceilingLevel or 0) end
		if ceilingBtn then
			ceilingBtn.Text = tostring(ceilingCost) .. "    "
			ceilingBtn.BackgroundColor3 = Color3.fromRGB(150, 80, 150)
			if ceilingBtn:FindFirstChild("CurrencyIcon") then ceilingBtn.CurrencyIcon.Visible = true end
		end
	end

	-- Floor Upgrade cost
	local floorDesc = floorUpgradeRow:FindFirstChild("Desc")
	local floorBtn = floorUpgradeRow:FindFirstChild("BuyButton")
	
	local currentPoolSize = (currentMaxTier - (data.floorLevel or 0)) + 1
	if currentPoolSize <= Config.MIN_TABLE_SIZE then
		if floorDesc then floorDesc.Text = "Cannot narrow pool further" end
		if floorBtn then
			floorBtn.Text = "MAX"
			floorBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		end
	else
		local rawFloorCost = Config.FLOOR_UPGRADE_BASE_COST * (Config.FLOOR_UPGRADE_COST_SCALE ^ (data.floorLevel or 0))
		local floorCost = math.floor(rawFloorCost / 100 + 0.5) * 100
		if floorDesc then floorDesc.Text = "Min Tier: +" .. (data.floorLevel or 0) end
		if floorBtn then
			floorBtn.Text = tostring(floorCost) .. "    "
			floorBtn.BackgroundColor3 = Color3.fromRGB(150, 80, 80)
			if floorBtn:FindFirstChild("CurrencyIcon") then floorBtn.CurrencyIcon.Visible = true end
		end
	end
end

dataChangedEvent.Event:Connect(function(data)
	updateCosts(data)
end)

-- State Polling on Init
local getStateFunc = stateFolder:WaitForChild("GetState")
local initialData = getStateFunc:Invoke()
if initialData then
	updateCosts(initialData)
end

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

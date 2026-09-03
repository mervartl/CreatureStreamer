--[[
	MobileNavBar.client.luau — Bottom navigation bar for toggling panels.
	Only visible when player is near a plot (proximity).
	Handles EggInventory and JobSlots panel toggling.
	Shop has its own always-visible corner button (see ShopScreen.client.luau).
]]

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local stateFolder = playerGui:WaitForChild("ClientState")
local proximityEvent = stateFolder:WaitForChild("PlotProximityChanged")

local mainUI = playerGui:WaitForChild("MainUI")
local ScreenManager = require(script.Parent:WaitForChild("ScreenManager"))

--------------------------------------------------------------------------------
-- Colors
--------------------------------------------------------------------------------

local COLOR_BG         = Color3.fromRGB(18, 18, 28)
local COLOR_BTN_IDLE   = Color3.fromRGB(32, 32, 48)
local COLOR_BTN_ACTIVE = Color3.fromRGB(50, 50, 72)
local COLOR_TEXT_IDLE  = Color3.fromRGB(160, 160, 185)
local COLOR_TEXT_ACTIVE = Color3.fromRGB(235, 235, 255)

local DOT_EGG = Color3.fromRGB(255, 220, 80)
local DOT_JOB = Color3.fromRGB(100, 200, 255)

--------------------------------------------------------------------------------
-- NavBar frame — hidden until proximity
--------------------------------------------------------------------------------

local navBar = Instance.new("Frame")
navBar.Name = "MobileNavBar"
navBar.Size = UDim2.new(0, 64, 0, 160)
navBar.AnchorPoint = Vector2.new(1, 0.5)
navBar.Position = UDim2.new(1, -16, 0.5, 0) -- right side, aligned with shop toggle
navBar.BackgroundColor3 = COLOR_BG
navBar.BackgroundTransparency = 1 -- fully transparent, just floating buttons
navBar.BorderSizePixel = 0
navBar.ZIndex = 50
navBar.ClipsDescendants = false
navBar.Visible = false  -- hidden by default, shown on proximity
navBar.Parent = mainUI

local uiScale = Instance.new("UIScale")
uiScale.Scale = 1.0
uiScale.Parent = navBar

-- Container for the buttons
local btnContainer = Instance.new("Frame")
btnContainer.Size = UDim2.new(1, 0, 1, 0)
btnContainer.BackgroundTransparency = 1
btnContainer.Parent = navBar

-- Vertical layout
local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
listLayout.Padding = UDim.new(0, 12)
listLayout.Parent = btnContainer

--------------------------------------------------------------------------------
-- Button factory
--------------------------------------------------------------------------------

local function makeNavBtn(name, icon, label, dotColor)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 64, 0, 64) -- square button
	btn.BackgroundColor3 = COLOR_BTN_IDLE
	btn.BorderSizePixel = 0
	btn.Text = icon .. "\n" .. label
	btn.TextColor3 = COLOR_TEXT_IDLE
	btn.TextSize = 12
	btn.Font = Enum.Font.GothamBold
	btn.AutoButtonColor = false
	btn.ZIndex = 51
	btn.Parent = btnContainer
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

	-- Active indicator dot (top center)
	local dot = Instance.new("Frame")
	dot.Name = "ActiveDot"
	dot.Size = UDim2.new(0, 8, 0, 8)
	dot.Position = UDim2.new(0.5, -4, 0, 4)
	dot.BackgroundColor3 = dotColor
	dot.BorderSizePixel = 0
	dot.Visible = false
	dot.ZIndex = 52
	dot.Parent = btn
	Instance.new("UICorner", dot).CornerRadius = UDim.new(0.5, 0)

	return btn
end

local eggBtn = makeNavBtn("EggNavBtn", "🥚", "Vajíčka", DOT_EGG)
local jobBtn = makeNavBtn("JobNavBtn", "📺", "Jobs",    DOT_JOB)

--------------------------------------------------------------------------------
-- Panel state helpers
--------------------------------------------------------------------------------

local PANEL_EGG = "EggInventoryFrame"
local PANEL_JOB = "JobSlotsFrame"

local function getFrame(name)
	return mainUI:FindFirstChild(name)
end

local function setPanelActive(btn, frameName, active)
	local frame = getFrame(frameName)
	if frame then
		frame.Visible = active
	end
	local dot = btn:FindFirstChild("ActiveDot")
	if dot then dot.Visible = active end
	btn.BackgroundColor3 = active and COLOR_BTN_ACTIVE or COLOR_BTN_IDLE
	btn.TextColor3 = active and COLOR_TEXT_ACTIVE or COLOR_TEXT_IDLE
end

local function isPanelOpen(frameName)
	local frame = getFrame(frameName)
	return frame ~= nil and frame.Visible
end

local function closeAllPanels()
	setPanelActive(eggBtn, PANEL_EGG, false)
	setPanelActive(jobBtn, PANEL_JOB, false)
end

--------------------------------------------------------------------------------
-- Button click handlers
-- No proximity check needed — navBar is only visible when near platform
--------------------------------------------------------------------------------

eggBtn.MouseButton1Click:Connect(function()
	local willOpen = not isPanelOpen(PANEL_EGG)
	closeAllPanels()
	setPanelActive(eggBtn, PANEL_EGG, willOpen)
end)

jobBtn.MouseButton1Click:Connect(function()
	local willOpen = not isPanelOpen(PANEL_JOB)
	closeAllPanels()
	setPanelActive(jobBtn, PANEL_JOB, willOpen)
end)

--------------------------------------------------------------------------------
-- Proximity sync — navBar shows/hides with platform proximity
--------------------------------------------------------------------------------

proximityEvent.Event:Connect(function(near)
	navBar.Visible = near
	if not near then
		-- Force-close panels and reset button states when leaving platform
		closeAllPanels()
	end
end)

--------------------------------------------------------------------------------
-- Responsive Layout
--------------------------------------------------------------------------------

local function applyScreen(info)
	if info.deviceClass == "Mobile" then
		uiScale.Scale = info.scale
		navBar.Position = UDim2.new(1, -10, 0.5, 0)
	elseif info.deviceClass == "Tablet" then
		uiScale.Scale = info.scale * 1.15
		navBar.Position = UDim2.new(1, -16, 0.5, 0)
	else
		uiScale.Scale = info.scale * 1.25
		navBar.Position = UDim2.new(1, -20, 0.5, 0)
	end
end

ScreenManager.ScreenChanged:Connect(applyScreen)
if ScreenManager.CurrentClass then
	applyScreen({
		deviceClass = ScreenManager.CurrentClass,
		scale = ScreenManager.CurrentScale
	})
end

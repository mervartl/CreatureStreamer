--[[
	HatchInteraction.client.luau
	Replaces the old HatchScreen UI.
	Detects clicks on the physical HatchStation in the player's plot,
	fires the server remote, and plays a 3D celebration (particles, sound, text)
	based on the rarity of the hatched egg.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local TierData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TierData"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local stateFolder = playerGui:WaitForChild("ClientState")
local Remotes = stateFolder:WaitForChild("RemotesRef").Value
local HatchEgg = Remotes:WaitForChild("HatchEgg")

local debounce = false

-- Set up generic sound IDs for different rarities
local SOUND_IDS = {
	Common = "rbxasset://sounds/switch.mp3",
	Rare = "rbxasset://sounds/electronicpingshort.wav",
	Epic = "rbxasset://sounds/electronicpingshort.wav",
	Legendary = "rbxasset://sounds/electronicpingshort.wav"
}

-- Find the plot and hatch station
task.spawn(function()
	local plotName = player.Name .. "_Plot"
	local plot = Workspace:WaitForChild(plotName, 60)
	if not plot then return end
	
	local hatchStation = plot:WaitForChild("HatchStation", 10)
	if not hatchStation then return end
	
	local clickDetector = hatchStation:FindFirstChildOfClass("ClickDetector")
	if not clickDetector then return end
	
	-- Sound Emitter
	local soundEmitter = Instance.new("Sound")
	soundEmitter.Parent = hatchStation
	
	-- Particle Emitter
	local particleEmitter = Instance.new("ParticleEmitter")
	particleEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	particleEmitter.Enabled = false
	particleEmitter.Lifetime = NumberRange.new(0.5, 1.2)
	particleEmitter.Speed = NumberRange.new(5, 12)
	particleEmitter.SpreadAngle = Vector2.new(180, 180)
	particleEmitter.Parent = hatchStation
	
	-- Point Light
	local pointLight = Instance.new("PointLight")
	pointLight.Range = 12
	pointLight.Brightness = 0
	pointLight.Parent = hatchStation
	
	-- Billboard Gui for Text
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 250, 0, 60)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = ""
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextStrokeTransparency = 0
	textLabel.Parent = billboard
	
	billboard.Parent = hatchStation
	
	local function playHatchCelebration(tierInfo)
		local rarityName = tierInfo.rarityName
		
		-- Configure based on rarity
		local emitCount = 10
		local duration = 1.0
		local soundId = SOUND_IDS[rarityName] or SOUND_IDS.Common
		local pitch = 1
		local volume = 0.5
		local lightBrightness = 2
		local textScale = 1.0
		
		if rarityName == "Common" then
			emitCount = 5
			duration = 0.8
		elseif rarityName == "Rare" then
			emitCount = 20
			volume = 0.8
			lightBrightness = 4
			textScale = 1.2
		elseif rarityName == "Epic" then
			emitCount = 40
			volume = 1.2
			lightBrightness = 7
			textScale = 1.5
		elseif rarityName == "Legendary" then
			emitCount = 80
			duration = 2.0
			pitch = 0.8
			volume = 2.0
			lightBrightness = 12
			textScale = 2.0
			
			-- Fullscreen flash for Legendary
			local flashGui = Instance.new("ScreenGui")
			flashGui.Parent = playerGui
			local flashFrame = Instance.new("Frame")
			flashFrame.Size = UDim2.new(1, 0, 1, 0)
			flashFrame.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
			flashFrame.BackgroundTransparency = 0.15
			flashFrame.BorderSizePixel = 0
			flashFrame.Parent = flashGui
			
			local ts = TweenService:Create(flashFrame, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {BackgroundTransparency = 1})
			ts:Play()
			ts.Completed:Connect(function() flashGui:Destroy() end)
		end
		
		-- Setup effects
		soundEmitter.SoundId = soundId
		soundEmitter.PlaybackSpeed = pitch
		soundEmitter.Volume = volume
		soundEmitter:Play()
		
		particleEmitter.Color = ColorSequence.new(tierInfo.color)
		particleEmitter:Emit(emitCount)
		
		pointLight.Color = tierInfo.color
		pointLight.Brightness = lightBrightness
		
		textLabel.Text = "+1 " .. tierInfo.displayName .. "!"
		textLabel.TextColor3 = tierInfo.color
		textLabel.TextTransparency = 0
		textLabel.TextStrokeTransparency = 0
		
		-- Tween light and text
		local tInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(pointLight, tInfo, {Brightness = 0}):Play()
		
		-- Tween text fading
		local startOffset = Vector3.new(0, 4, 0)
		billboard.StudsOffset = startOffset
		
		local textTween = TweenService:Create(textLabel, tInfo, {TextTransparency = 1, TextStrokeTransparency = 1})
		textTween:Play()
		
		-- Tween billboard moving upwards
		local offsetValue = Instance.new("Vector3Value")
		offsetValue.Value = startOffset
		offsetValue.Changed:Connect(function(val)
			billboard.StudsOffset = val
		end)
		
		local moveTween = TweenService:Create(offsetValue, tInfo, {Value = startOffset + Vector3.new(0, 4 * textScale, 0)})
		moveTween:Play()
		moveTween.Completed:Connect(function()
			offsetValue:Destroy()
		end)
	end
	
	clickDetector.MouseClick:Connect(function()
		if debounce then return end
		debounce = true
		
		local success, result = HatchEgg:InvokeServer()
		
		if success then
			local tierInfo = TierData.get(result.tier)
			playHatchCelebration(tierInfo)
		else
			-- Failed (no money / no slots). Show error briefly.
			textLabel.Text = "❌ " .. tostring(result)
			textLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			textLabel.TextTransparency = 0
			textLabel.TextStrokeTransparency = 0
			billboard.StudsOffset = Vector3.new(0, 4, 0)
			
			local tInfo = TweenInfo.new(1)
			TweenService:Create(textLabel, tInfo, {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		end
		
		-- Very short cooldown to match common hatch speed
		task.wait(0.2)
		debounce = false
	end)
end)

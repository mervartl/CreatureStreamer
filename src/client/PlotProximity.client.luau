--[[
	PlotProximity.client.luau
	Periodically checks distance to the player's plot and fires a BindableEvent
	in ClientState for UI toggling.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local stateFolder = playerGui:WaitForChild("ClientState")

-- Create the event
local proximityEvent = Instance.new("BindableEvent")
proximityEvent.Name = "PlotProximityChanged"
proximityEvent.Parent = stateFolder

local isNearPlot = false

local function checkProximity()
	local character = player.Character
	if not character then return end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	local plotName = player.Name .. "_Plot"
	local plot = Workspace:FindFirstChild(plotName)
	if not plot then return end
	
	local plotCenter = plot:GetPivot().Position
	
	-- Flatten Y for a 2D cylinder check if desired, but 3D magnitude is fine too.
	local distance = (hrp.Position - plotCenter).Magnitude
	
	local currentlyNear = distance <= Config.PROXIMITY_RADIUS
	
	if currentlyNear ~= isNearPlot then
		isNearPlot = currentlyNear
		proximityEvent:Fire(isNearPlot)
	end
end

-- Run every ~0.25s instead of every frame
task.spawn(function()
	while true do
		checkProximity()
		task.wait(0.25)
	end
end)

--[[
	PlotSystem.luau — Manages 3D plots for each player.
	Clones PlotTemplate for players, handles grid positioning,
	and manages physical primitives representing active workers.
]]

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local TierData = require(ReplicatedStorage.Shared.TierData)
local DataStoreManager = require(script.Parent.DataStoreManager)

local PlotSystem = {}

local activePlots = {} -- [Player.UserId] = Model
local takenGridSlots = {} -- [index] = true

--- Get the plot for a specific player.
--- @param player Player
--- @return Model|nil
function PlotSystem.getPlotForPlayer(player: Player)
	return activePlots[player.UserId]
end

--- Assign a plot to the player upon joining.
--- @param player Player
function PlotSystem.assignPlot(player: Player)
	if activePlots[player.UserId] then
		warn("[PlotSystem] Player already has a plot assigned.")
		return
	end

	local gridIndex = nil
	for i = 1, Config.MAX_PLOTS do
		if not takenGridSlots[i] then
			gridIndex = i
			break
		end
	end

	if not gridIndex then
		warn("[PlotSystem] Soft limit reached! No available plots for " .. player.Name)
		return
	end

	takenGridSlots[gridIndex] = true

	local template = ServerStorage:FindFirstChild("PlotTemplate")
	if not template then
		warn("[PlotSystem] PlotTemplate not found in ServerStorage!")
		return
	end

	local plot = template:Clone()
	plot.Name = player.Name .. "_Plot"
	
	-- Anchor all parts to prevent physics engine from pushing the plot up/down
	for _, desc in ipairs(plot:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.Anchored = true
		end
	end

	-- Keep the original Y position and rotation from the template
	local originalPivot = template:GetPivot()
	local originalY = originalPivot.Position.Y
	
	-- Position the plot in a circle around the center (0, originalY, 0)
	local angle = (gridIndex / Config.MAX_PLOTS) * math.pi * 2
	local plotPosition = Vector3.new(
		math.cos(angle) * Config.PLOT_RADIUS,
		originalY,
		math.sin(angle) * Config.PLOT_RADIUS
	)
	
	-- Orient the plot so it faces the center of the island
	local centerPosition = Vector3.new(0, originalY, 0)
	-- CFrame.lookAt points the front of the model towards the target
	local lookAtCFrame = CFrame.lookAt(plotPosition, centerPosition)
	plot:PivotTo(lookAtCFrame)
	
	-- Parent to Workspace AFTER positioning and anchoring
	plot.Parent = Workspace

	-- Store extra data on the plot to know its index
	plot:SetAttribute("GridIndex", gridIndex)
	
	activePlots[player.UserId] = plot
	print("[PlotSystem] Assigned plot index " .. gridIndex .. " to " .. player.Name)
end

--- Remove a player's plot upon leaving.
--- @param player Player
function PlotSystem.removePlot(player: Player)
	local plot = activePlots[player.UserId]
	if plot then
		local gridIndex = plot:GetAttribute("GridIndex")
		if gridIndex then
			takenGridSlots[gridIndex] = false
		end
		plot:Destroy()
		activePlots[player.UserId] = nil
	end
end

--- Clear all worker primitives from the plot.
--- @param plot Model
local function clearPlotWorkers(plot: Model)
	for i = 1, Config.JOB_SLOTS_MAX do
		local slot = plot:FindFirstChild("JobSlot" .. i)
		if slot then
			for _, child in ipairs(slot:GetChildren()) do
				if child.Name:sub(1, 7) == "Worker_" then
					child:Destroy()
				end
			end
		end
	end
end

--- Render a single worker primitive into a slot.
local function renderWorkerPrimitive(worker, slot)
	local part = Instance.new("Part")
	part.Name = "Worker_" .. worker.id
	
	-- Size based on tier (and scaled globally)
	part.Size = (Config.WORKER_BASE_SIZE + Vector3.new(1, 1, 1) * (Config.WORKER_SIZE_PER_TIER * worker.tier)) * Config.WORKER_VISUAL_SCALE
	
	-- Color based on tier
	part.Color = TierData.getColor(worker.tier)
	
	-- Primitive visual settings
	part.Shape = Enum.PartType.Block
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	
	-- Position at the slot center + half of both heights so it sits exactly on top
	part.Position = slot.Position + Vector3.new(0, (slot.Size.Y / 2) + (part.Size.Y / 2) - 1, 0)
	
	-- Deterministic random rotation based on worker ID so they don't spin when re-rendered
	local seed = 0
	for i = 1, #worker.id do
		seed = seed + string.byte(worker.id, i)
	end
	local rng = Random.new(seed)
	part.CFrame = part.CFrame * CFrame.Angles(0, rng:NextNumber() * math.pi * 2, 0)
	
	part.Parent = slot
end

--- Spawn a single worker primitive on the plot (used for new assignments).
--- @param player Player
--- @param worker table
function PlotSystem.spawnWorker(player: Player, worker: table)
	local plot = activePlots[player.UserId]
	if not plot then
		warn("[PlotSystem] Cannot spawn worker: No plot assigned for " .. player.Name)
		return
	end

	local data = DataStoreManager.getData(player)
	if not data then return end

	-- Find index in data to know which slot
	local workerIndex = nil
	for i, w in ipairs(data.workers) do
		if w.id == worker.id then
			workerIndex = i
			break
		end
	end

	if not workerIndex then return end

	local slotName = "JobSlot" .. workerIndex
	local slot = plot:FindFirstChild(slotName)
	if not slot then
		warn("[PlotSystem] Slot " .. slotName .. " not found in PlotTemplate!")
		return
	end

	renderWorkerPrimitive(worker, slot)
end

--- Despawn a worker and reorganize the plot.
--- @param player Player
--- @param workerId string
function PlotSystem.despawnWorker(player: Player, workerId: string)
	-- To handle index shifting, the safest and easiest way is to fully re-render.
	PlotSystem.renderAllWorkers(player)
end

--- Completely re-render all active workers on a player's plot.
--- @param player Player
function PlotSystem.renderAllWorkers(player: Player)
	local plot = activePlots[player.UserId]
	if not plot then return end

	local data = DataStoreManager.getData(player)
	if not data then return end

	clearPlotWorkers(plot)

	for i, worker in ipairs(data.workers) do
		local slot = plot:FindFirstChild("JobSlot" .. i)
		if slot then
			renderWorkerPrimitive(worker, slot)
		end
	end
end

return PlotSystem

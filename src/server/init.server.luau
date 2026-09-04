--[[
	Server Bootstrap — init.server.luau
	Wires up all remote handlers, player lifecycle events,
	and starts background loops (passive income, autosave).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remote references
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local HatchEggRemote = Remotes:WaitForChild("HatchEgg")
local MergeEggsRemote = Remotes:WaitForChild("MergeEggs")
local SellEggRemote = Remotes:WaitForChild("SellEgg")
local AssignEggToJobRemote = Remotes:WaitForChild("AssignEggToJob")
local SellWorkerRemote = Remotes:WaitForChild("SellWorker")
local BuySlotRemote = Remotes:WaitForChild("BuySlot")
local BuyUpgradeRemote = Remotes:WaitForChild("BuyUpgrade")
local ClaimSessionRewardRemote = Remotes:WaitForChild("ClaimSessionReward")
local ClaimDailyRewardRemote = Remotes:WaitForChild("ClaimDailyReward")
local SyncPlayerDataRemote = Remotes:WaitForChild("SyncPlayerData")

local RequestSyncRemote = Instance.new("RemoteFunction")
RequestSyncRemote.Name = "RequestSync"
RequestSyncRemote.Parent = Remotes

-- System modules
local DataStoreManager = require(script.Systems.DataStoreManager)
local HatchSystem = require(script.Systems.HatchSystem)
local MergeSystem = require(script.Systems.MergeSystem)
local JobAssignmentSystem = require(script.Systems.JobAssignmentSystem)
local CurrencySystem = require(script.Systems.CurrencySystem)
local LuckSystem = require(script.Systems.LuckSystem)
local SlotSystem = require(script.Systems.SlotSystem)
local UpgradeSystem = require(script.Systems.UpgradeSystem)
local SessionRewardSystem = require(script.Systems.SessionRewardSystem)
local DailyRewardSystem = require(script.Systems.DailyRewardSystem)
local MarketplaceHandler = require(script.Systems.MarketplaceHandler)
local PlotSystem = require(script.Systems.PlotSystem)
local DebugSystem = require(script.Systems.DebugSystem)

local Config = require(ReplicatedStorage.Shared.Config)

--------------------------------------------------------------------------------
-- Helper: send updated state to client after any mutation
--------------------------------------------------------------------------------
local function syncToClient(player: Player)
	local clientData = DataStoreManager.getClientData(player)
	if clientData then
		SyncPlayerDataRemote:FireClient(player, clientData)
	end
end

--------------------------------------------------------------------------------
-- Remote handlers
--------------------------------------------------------------------------------

HatchEggRemote.OnServerInvoke = function(player)
	local success, result = HatchSystem.hatch(player)
	syncToClient(player)
	return success, result
end

MergeEggsRemote.OnServerInvoke = function(player, eggId1, eggId2)
	if type(eggId1) ~= "string" or type(eggId2) ~= "string" then
		return false, "Invalid egg IDs"
	end
	local success, result = MergeSystem.merge(player, eggId1, eggId2)
	syncToClient(player)
	return success, result
end

SellEggRemote.OnServerInvoke = function(player, eggId)
	if type(eggId) ~= "string" then
		return false, "Invalid egg ID"
	end
	local success, result = CurrencySystem.sellEgg(player, eggId)
	syncToClient(player)
	return success, result
end

AssignEggToJobRemote.OnServerInvoke = function(player, eggId)
	if type(eggId) ~= "string" then
		return false, "Invalid egg ID"
	end
	local success, result = JobAssignmentSystem.assign(player, eggId)
	syncToClient(player)
	return success, result
end

SellWorkerRemote.OnServerInvoke = function(player, workerId)
	if type(workerId) ~= "string" then
		return false, "Invalid worker ID"
	end
	local success, result = CurrencySystem.sellWorker(player, workerId)
	syncToClient(player)
	return success, result
end

BuySlotRemote.OnServerInvoke = function(player, slotType)
	if type(slotType) ~= "string" then
		return false, "Invalid slot type"
	end
	local success, result = SlotSystem.buySlot(player, slotType)
	syncToClient(player)
	return success, result
end

BuyUpgradeRemote.OnServerInvoke = function(player, upgradeType)
	if type(upgradeType) ~= "string" then
		return false, "Invalid upgrade type"
	end
	local success, result = UpgradeSystem.buyUpgrade(player, upgradeType)
	syncToClient(player)
	return success, result
end

ClaimSessionRewardRemote.OnServerEvent:Connect(function(player, milestoneIndex)
	if type(milestoneIndex) ~= "number" then
		return
	end
	SessionRewardSystem.claim(player, milestoneIndex)
	syncToClient(player)
end)

ClaimDailyRewardRemote.OnServerEvent:Connect(function(player)
	DailyRewardSystem.claim(player)
	syncToClient(player)
end)

RequestSyncRemote.OnServerInvoke = function(player)
	local data = DataStoreManager.getClientData(player)
	-- If DataStore is still loading this player's data, wait for it
	while not data and player.Parent do
		task.wait(0.2)
		data = DataStoreManager.getClientData(player)
	end
	return data
end

--------------------------------------------------------------------------------
-- Player lifecycle
--------------------------------------------------------------------------------

Players.PlayerAdded:Connect(function(player)
	-- Load data from DataStore
	local data = DataStoreManager.loadPlayerData(player)

	-- Check gamepass ownership
	LuckSystem.checkLuckPass(player)

	-- Assign Plot and render existing workers
	PlotSystem.assignPlot(player)
	PlotSystem.renderAllWorkers(player)

	-- Send initial state to client
	syncToClient(player)

	-- Check daily reward eligibility and notify
	local canClaim, nextDay = DailyRewardSystem.canClaim(player)
	if canClaim then
		-- Client will see this in the synced data and show popup
		-- (eligibility is determined client-side from the synced date)
	end

	-- Initialize debug commands for this player
	DebugSystem.init(player, syncToClient)

	print("[Server] Player loaded:", player.Name, "| Currency:", data.currency, "| Eggs:", #data.eggs, "| Workers:", #data.workers)
end)

Players.PlayerRemoving:Connect(function(player)
	PlotSystem.removePlot(player)
	DataStoreManager.savePlayerData(player)
	DataStoreManager.clearCache(player)
	LuckSystem.clearCache(player)
end)

-- Save all on server shutdown
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			DataStoreManager.savePlayerData(player)
		end)
	end
	-- Give saves time to complete
	task.wait(3)
end)

--------------------------------------------------------------------------------
-- Background loops
--------------------------------------------------------------------------------

-- Passive income tick loop
task.spawn(function()
	while true do
		task.wait(Config.INCOME_TICK_SECONDS)
		for _, player in ipairs(Players:GetPlayers()) do
			local income = CurrencySystem.tickPassiveIncome(player)
			if income > 0 then
				syncToClient(player)
			end
		end
	end
end)

-- Session reward eligibility check loop (every 10 seconds)
task.spawn(function()
	while true do
		task.wait(10)
		for _, player in ipairs(Players:GetPlayers()) do
			local claimable = SessionRewardSystem.getClaimableMilestones(player)
			if #claimable > 0 then
				syncToClient(player)
			end
		end
	end
end)

-- Start autosave loop
DataStoreManager.startAutosaveLoop()

-- Initialize marketplace handlers
MarketplaceHandler.init()

print("[Server] Creature Streamer server initialized successfully!")

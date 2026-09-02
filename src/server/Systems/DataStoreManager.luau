--[[
	DataStoreManager.luau — Handles player data persistence.
	Uses UpdateAsync with exponential backoff for reliability.
	Saves on PlayerRemoving, autosave loop, and BindToClose.
]]

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Config = require(game.ReplicatedStorage.Shared.Config)

local DataStoreManager = {}

-- In-memory cache of loaded player data, keyed by Player.UserId
local playerDataCache = {}

-- The DataStore instance
local dataStore = DataStoreService:GetDataStore(Config.DATASTORE_NAME)

--- Default data template for a new player.
local function getDefaultData()
	return {
		currency = Config.STARTING_CURRENCY,
		eggs = {},          -- array of { tier: number, id: string }
		workers = {},       -- array of { tier: number, id: string }
		eggSlotsCap = Config.EGG_SLOTS_INITIAL,
		jobSlotsCap = Config.JOB_SLOTS_INITIAL,
		luck = Config.BASE_LUCK,
		hasLuckPass = false,
		sessionStartTime = 0,           -- set at load time
		sessionRewardsClaimed = {},      -- { [1]=bool, [2]=bool }
		sessionLuckBoost = 0,            -- temporary luck boost from session reward
		dailyStreak = 0,
		lastDailyClaimDate = "",         -- "YYYY-MM-DD"
	}
end

--- Generate the DataStore key for a player.
local function getKey(player: Player): string
	return Config.DATASTORE_KEY_PREFIX .. tostring(player.UserId)
end

--- Attempt a DataStore operation with exponential backoff.
--- @param operation string — description for logging
--- @param callback function — the pcall-wrapped function to attempt
--- @return boolean, any — success, result or error
local function withRetry(operation: string, callback)
	for attempt = 1, Config.DATASTORE_MAX_RETRIES do
		local success, result = pcall(callback)
		if success then
			return true, result
		end

		warn(string.format(
			"[DataStoreManager] %s failed (attempt %d/%d): %s",
			operation, attempt, Config.DATASTORE_MAX_RETRIES, tostring(result)
		))

		if attempt < Config.DATASTORE_MAX_RETRIES then
			task.wait(2 ^ attempt)
		end
	end

	return false, "Exhausted retries for " .. operation
end

--- Load player data from DataStore (or create defaults).
--- Call this on PlayerAdded.
function DataStoreManager.loadPlayerData(player: Player)
	local key = getKey(player)

	local success, savedData = withRetry("LoadData:" .. key, function()
		return dataStore:GetAsync(key)
	end)

	local data
	if success and savedData then
		-- Merge saved data onto defaults so new fields get default values
		data = getDefaultData()
		for k, v in pairs(savedData) do
			data[k] = v
		end
	else
		data = getDefaultData()
		if not success then
			warn("[DataStoreManager] Could not load data for " .. player.Name .. ", using defaults")
		end
	end

	-- Reset session-specific fields
	data.sessionStartTime = os.clock()
	data.sessionRewardsClaimed = {}
	data.sessionLuckBoost = 0

	-- Ensure all eggs/workers have IDs (migration safety)
	for _, egg in ipairs(data.eggs) do
		if not egg.id then
			egg.id = HttpService:GenerateGUID(false)
		end
	end
	for _, worker in ipairs(data.workers) do
		if not worker.id then
			worker.id = HttpService:GenerateGUID(false)
		end
	end

	playerDataCache[player.UserId] = data
	return data
end

--- Save player data to DataStore.
function DataStoreManager.savePlayerData(player: Player)
	local data = playerDataCache[player.UserId]
	if not data then
		return
	end

	local key = getKey(player)

	-- Strip session-only fields before saving
	local toSave = {}
	for k, v in pairs(data) do
		toSave[k] = v
	end
	toSave.sessionStartTime = nil
	toSave.sessionRewardsClaimed = nil
	toSave.sessionLuckBoost = nil

	local success, err = withRetry("SaveData:" .. key, function()
		dataStore:UpdateAsync(key, function(_oldData)
			return toSave
		end)
	end)

	if not success then
		warn("[DataStoreManager] CRITICAL: Failed to save data for " .. player.Name .. ": " .. tostring(err))
	end
end

--- Get the in-memory data for a player (returns nil if not loaded).
function DataStoreManager.getData(player: Player)
	return playerDataCache[player.UserId]
end

--- Remove player from cache (call after save on PlayerRemoving).
function DataStoreManager.clearCache(player: Player)
	playerDataCache[player.UserId] = nil
end

--- Get a sanitized copy of player data safe to send to the client.
--- Omits internal fields the client shouldn't see.
function DataStoreManager.getClientData(player: Player)
	local data = playerDataCache[player.UserId]
	if not data then
		return nil
	end

	return {
		currency = data.currency,
		eggs = data.eggs,
		workers = data.workers,
		eggSlotsCap = data.eggSlotsCap,
		jobSlotsCap = data.jobSlotsCap,
		luck = data.luck,
		hasLuckPass = data.hasLuckPass,
		sessionLuckBoost = data.sessionLuckBoost,
		dailyStreak = data.dailyStreak,
		lastDailyClaimDate = data.lastDailyClaimDate,
		sessionStartTime = data.sessionStartTime,
		sessionRewardsClaimed = data.sessionRewardsClaimed,
	}
end

--- Start the autosave loop (call once from server bootstrap).
function DataStoreManager.startAutosaveLoop()
	task.spawn(function()
		while true do
			task.wait(Config.AUTOSAVE_INTERVAL)
			for _, player in ipairs(Players:GetPlayers()) do
				task.spawn(function()
					DataStoreManager.savePlayerData(player)
				end)
			end
		end
	end)
end

return DataStoreManager

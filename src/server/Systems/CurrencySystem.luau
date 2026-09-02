--[[
	CurrencySystem.luau — Handles direct sells and passive income ticks.
	All currency modifications are server-authoritative.
]]

local Config = require(game.ReplicatedStorage.Shared.Config)
local DataStoreManager = require(script.Parent.DataStoreManager)
local PlotSystem = require(script.Parent.PlotSystem)

local CurrencySystem = {}

--- Find an egg/worker in a list by ID.
local function findById(list, id: string)
	for i, item in ipairs(list) do
		if item.id == id then
			return i, item
		end
	end
	return nil, nil
end

--- Sell an egg directly from the merge pool (no hatch).
--- @param player Player
--- @param eggId string
--- @return boolean success, number|string result — currency gained or error
function CurrencySystem.sellEgg(player: Player, eggId: string)
	local data = DataStoreManager.getData(player)
	if not data then
		return false, "Data not loaded"
	end

	local idx, egg = findById(data.eggs, eggId)
	if not egg then
		return false, "Egg not found"
	end

	local value = Config.SELL_EGG_VALUE_PER_TIER[egg.tier] or 0
	table.remove(data.eggs, idx)
	data.currency = data.currency + value

	return true, value
end

--- Sell (liquidate) an active worker.
--- @param player Player
--- @param workerId string
--- @return boolean success, number|string result — currency gained or error
function CurrencySystem.sellWorker(player: Player, workerId: string)
	local data = DataStoreManager.getData(player)
	if not data then
		return false, "Data not loaded"
	end

	local idx, worker = findById(data.workers, workerId)
	if not worker then
		return false, "Worker not found"
	end

	local value = Config.SELL_WORKER_VALUE_PER_TIER[worker.tier] or 0
	table.remove(data.workers, idx)
	data.currency = data.currency + value
	
	PlotSystem.despawnWorker(player, workerId)

	return true, value
end

--- Calculate and award passive income from all active workers.
--- Called once per INCOME_TICK_SECONDS by the tick loop.
--- @param player Player
--- @return number totalIncome — currency earned this tick
function CurrencySystem.tickPassiveIncome(player: Player): number
	local data = DataStoreManager.getData(player)
	if not data then
		return 0
	end

	local totalIncome = 0
	for _, worker in ipairs(data.workers) do
		local income = Config.INCOME_PER_TIER[worker.tier] or 0
		totalIncome = totalIncome + income
	end

	data.currency = data.currency + totalIncome
	return totalIncome
end

--- Add currency directly (used by reward systems, dev products, etc.).
--- @param player Player
--- @param amount number
function CurrencySystem.addCurrency(player: Player, amount: number)
	local data = DataStoreManager.getData(player)
	if not data then
		return
	end
	data.currency = data.currency + amount
end

return CurrencySystem

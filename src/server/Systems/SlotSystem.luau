--[[
	SlotSystem.luau — Egg inventory cap and job slot cap expansion.
	Cost escalates per additional slot purchased.
]]

local Config = require(game.ReplicatedStorage.Shared.Config)
local DataStoreManager = require(script.Parent.DataStoreManager)

local SlotSystem = {}

--- Calculate the cost of the next slot expansion.
--- Formula: BASE_COST * SCALE ^ (currentCap - initialCap)
local function calculateCost(baseCost: number, costScale: number, currentCap: number, initialCap: number): number
	local slotsBought = currentCap - initialCap
	return math.floor(baseCost * (costScale ^ slotsBought))
end

--- Get the cost of the next egg slot expansion.
function SlotSystem.getEggSlotCost(player: Player): number
	local data = DataStoreManager.getData(player)
	if not data then
		return math.huge
	end
	return calculateCost(
		Config.EGG_SLOT_BASE_COST,
		Config.EGG_SLOT_COST_SCALE,
		data.eggSlotsCap,
		Config.EGG_SLOTS_INITIAL
	)
end

--- Get the cost of the next job slot expansion.
function SlotSystem.getJobSlotCost(player: Player): number
	local data = DataStoreManager.getData(player)
	if not data then
		return math.huge
	end
	return calculateCost(
		Config.JOB_SLOT_BASE_COST,
		Config.JOB_SLOT_COST_SCALE,
		data.jobSlotsCap,
		Config.JOB_SLOTS_INITIAL
	)
end

--- Buy a slot expansion.
--- @param player Player
--- @param slotType string — "egg" or "job"
--- @return boolean success, string result — "ok" or error message
function SlotSystem.buySlot(player: Player, slotType: string)
	local data = DataStoreManager.getData(player)
	if not data then
		return false, "Data not loaded"
	end

	if slotType == "egg" then
		if data.eggSlotsCap >= Config.EGG_SLOTS_MAX then
			return false, "Already at maximum egg slots"
		end

		local cost = SlotSystem.getEggSlotCost(player)
		if data.currency < cost then
			return false, "Not enough currency"
		end

		data.currency = data.currency - cost
		data.eggSlotsCap = data.eggSlotsCap + 1
		return true, "ok"

	elseif slotType == "job" then
		if data.jobSlotsCap >= Config.JOB_SLOTS_MAX then
			return false, "Already at maximum job slots"
		end

		local cost = SlotSystem.getJobSlotCost(player)
		if data.currency < cost then
			return false, "Not enough currency"
		end

		data.currency = data.currency - cost
		data.jobSlotsCap = data.jobSlotsCap + 1
		return true, "ok"

	else
		return false, "Invalid slot type: " .. tostring(slotType)
	end
end

return SlotSystem

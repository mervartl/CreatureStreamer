--[[
	JobAssignmentSystem.luau — Irreversible egg → worker assignment.
	Removes egg from the mergeable pool, adds it to active workers.
	The egg "hatches" into a worker and can never merge again.
]]

local DataStoreManager = require(script.Parent.DataStoreManager)

local JobAssignmentSystem = {}

--- Find an egg in the player's inventory by ID.
local function findEgg(eggs, eggId: string)
	for i, egg in ipairs(eggs) do
		if egg.id == eggId then
			return i, egg
		end
	end
	return nil, nil
end

--- Assign an egg to a job slot. Irreversible.
--- @param player Player
--- @param eggId string — ID of the egg to assign
--- @return boolean success, table|string result — the new worker or error message
function JobAssignmentSystem.assign(player: Player, eggId: string)
	local data = DataStoreManager.getData(player)
	if not data then
		return false, "Data not loaded"
	end

	-- Check job slot capacity
	if #data.workers >= data.jobSlotsCap then
		return false, "All job slots are full"
	end

	-- Find the egg
	local idx, egg = findEgg(data.eggs, eggId)
	if not egg then
		return false, "Egg not found in inventory"
	end

	-- Remove from eggs (merge pool) — irreversible
	table.remove(data.eggs, idx)

	-- Add to workers with the same tier and id
	local worker = {
		tier = egg.tier,
		id = egg.id,
	}
	table.insert(data.workers, worker)

	return true, worker
end

return JobAssignmentSystem

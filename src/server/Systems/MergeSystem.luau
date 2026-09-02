--[[
	MergeSystem.luau — Server-side merge logic.
	Always: 2x tier N → 1x tier N+1. No special-casing at rarity boundaries.
]]

local HttpService = game:GetService("HttpService")

local Config = require(game.ReplicatedStorage.Shared.Config)
local DataStoreManager = require(script.Parent.DataStoreManager)

local MergeSystem = {}

--- Find an egg in the player's inventory by ID.
--- @return number|nil index, table|nil egg
local function findEgg(eggs, eggId: string)
	for i, egg in ipairs(eggs) do
		if egg.id == eggId then
			return i, egg
		end
	end
	return nil, nil
end

--- Attempt to merge two eggs of the same tier.
--- @param player Player
--- @param eggId1 string — ID of first egg
--- @param eggId2 string — ID of second egg
--- @return boolean success, table|string result — the merged egg or error message
function MergeSystem.merge(player: Player, eggId1: string, eggId2: string)
	local data = DataStoreManager.getData(player)
	if not data then
		return false, "Data not loaded"
	end

	if eggId1 == eggId2 then
		return false, "Cannot merge an egg with itself"
	end

	local idx1, egg1 = findEgg(data.eggs, eggId1)
	local idx2, egg2 = findEgg(data.eggs, eggId2)

	if not egg1 or not egg2 then
		return false, "One or both eggs not found"
	end

	if egg1.tier ~= egg2.tier then
		return false, "Eggs must be the same tier to merge"
	end

	if egg1.tier >= Config.TIER_MAX then
		return false, "Already at maximum tier"
	end

	-- Remove both eggs (remove higher index first to avoid shifting)
	local removeFirst = math.max(idx1, idx2)
	local removeSecond = math.min(idx1, idx2)
	table.remove(data.eggs, removeFirst)
	table.remove(data.eggs, removeSecond)

	-- Create merged egg at tier + 1
	local mergedEgg = {
		tier = egg1.tier + 1,
		id = HttpService:GenerateGUID(false),
	}

	table.insert(data.eggs, mergedEgg)

	return true, mergedEgg
end

return MergeSystem

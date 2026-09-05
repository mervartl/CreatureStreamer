--[[
	SessionRewardSystem.luau — Server-authoritative session timer rewards.
	Timer resets when the player leaves. Milestones require manual claim.
]]

local HttpService = game:GetService("HttpService")

local Config = require(game.ReplicatedStorage.Shared.Config)
local RarityUtil = require(game.ReplicatedStorage.Shared.RarityUtil)
local DataStoreManager = require(script.Parent.DataStoreManager)
local CurrencySystem = require(script.Parent.CurrencySystem)
local LuckSystem = require(script.Parent.LuckSystem)

local SessionRewardSystem = {}

--- Check which milestones the player is eligible for but hasn't claimed yet.
--- @param player Player
--- @return { number } — array of milestone indices (1-based) that are claimable
function SessionRewardSystem.getClaimableMilestones(player: Player): { number }
	local data = DataStoreManager.getData(player)
	if not data then
		return {}
	end

	local elapsed = workspace:GetServerTimeNow() - data.sessionStartTime
	local claimable = {}

	for i, milestone in ipairs(Config.SESSION_MILESTONES) do
		local alreadyClaimed = data.sessionRewardsClaimed[i]
		if elapsed >= milestone.time and not alreadyClaimed then
			table.insert(claimable, i)
		end
	end

	return claimable
end

--- Claim a specific session reward milestone.
--- @param player Player
--- @param milestoneIndex number — 1-based index into SESSION_MILESTONES
--- @return boolean success, string result
function SessionRewardSystem.claim(player: Player, milestoneIndex: number)
	local data = DataStoreManager.getData(player)
	if not data then
		return false, "Data not loaded"
	end

	local milestone = Config.SESSION_MILESTONES[milestoneIndex]
	if not milestone then
		return false, "Invalid milestone index"
	end

	-- Check eligibility
	local elapsed = workspace:GetServerTimeNow() - data.sessionStartTime
	if elapsed < milestone.time then
		return false, "Milestone not yet reached"
	end

	if data.sessionRewardsClaimed[milestoneIndex] then
		return false, "Already claimed"
	end

	-- Mark as claimed
	data.sessionRewardsClaimed[milestoneIndex] = true

	-- Award currency
	local baseCurrency = milestone.flatBase or 0
	local minutesMult = milestone.minutesMultiplier or 0
	local incomePerMinute = 0
	
	if minutesMult > 0 then
		local ticksPerMinute = 60 / Config.INCOME_TICK_SECONDS
		for _, worker in ipairs(data.workers) do
			incomePerMinute = incomePerMinute + (Config.INCOME_PER_TIER[worker.tier] or 0) * ticksPerMinute
		end
	end
	
	local rewardAmount = baseCurrency + (incomePerMinute * minutesMult)
	if rewardAmount > 0 then
		CurrencySystem.addCurrency(player, rewardAmount)
	end

	-- Apply session luck boost
	if milestone.luckBoost and milestone.luckBoost > 0 then
		data.sessionLuckBoost = (data.sessionLuckBoost or 0) + milestone.luckBoost
	end

	-- Award free egg at elevated minimum tier
	if milestone.freeEgg then
		local luck = LuckSystem.getEffectiveLuck(player)
		local floor = data.floorLevel or 0
		local bonus = milestone.freeEggMinTierBonus or 0
		local minTier = math.max(bonus, floor + bonus)
		
		local tier = RarityUtil.rollTierWithFloor(luck, minTier, data.ceilingLevel, floor)
		local newEgg = {
			tier = tier,
			id = HttpService:GenerateGUID(false),
		}
		-- Add to eggs if there's room, otherwise just give currency equivalent
		if #data.eggs < data.eggSlotsCap then
			table.insert(data.eggs, newEgg)
		else
			-- Fallback: give sell value instead if inventory is full
			local sellValue = Config.SELL_EGG_VALUE_PER_TIER[tier] or 0
			CurrencySystem.addCurrency(player, sellValue)
		end
	end

	return true, "Claimed milestone " .. tostring(milestoneIndex)
end

return SessionRewardSystem

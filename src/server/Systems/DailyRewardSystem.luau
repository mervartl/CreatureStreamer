--[[
	DailyRewardSystem.luau — Day-streak reward system.
	Checks date on join, awards escalating rewards for consecutive logins.
]]

local Config = require(game.ReplicatedStorage.Shared.Config)
local DataStoreManager = require(script.Parent.DataStoreManager)
local CurrencySystem = require(script.Parent.CurrencySystem)

local DailyRewardSystem = {}

--- Get today's date string in "YYYY-MM-DD" format (UTC).
local function getTodayString(): string
	return os.date("!%Y-%m-%d")
end

--- Get yesterday's date string in "YYYY-MM-DD" format (UTC).
local function getYesterdayString(): string
	return os.date("!%Y-%m-%d", os.time() - 86400)
end

--- Check if the player can claim their daily reward.
--- @param player Player
--- @return boolean canClaim, number nextDay — whether claimable and what day they'd be claiming
function DailyRewardSystem.canClaim(player: Player): (boolean, number)
	local data = DataStoreManager.getData(player)
	if not data then
		return false, 0
	end

	local today = getTodayString()

	-- Already claimed today
	if data.lastDailyClaimDate == today then
		return false, 0
	end

	-- Determine streak
	local yesterday = getYesterdayString()
	local nextDay

	if data.lastDailyClaimDate == yesterday then
		-- Consecutive day — continue streak
		nextDay = (data.dailyStreak % #Config.DAILY_REWARDS) + 1
	else
		-- Streak broken (or first ever claim)
		if Config.DAILY_STREAK_HARD_RESET then
			nextDay = 1
		else
			nextDay = 1  -- soft reset also goes to day 1 in v1
		end
	end

	return true, nextDay
end

--- Claim the daily reward.
--- @param player Player
--- @return boolean success, table|string result — reward info or error
function DailyRewardSystem.claim(player: Player)
	local data = DataStoreManager.getData(player)
	if not data then
		return false, "Data not loaded"
	end

	local canClaim, nextDay = DailyRewardSystem.canClaim(player)
	if not canClaim then
		return false, "Already claimed today"
	end

	local today = getTodayString()
	local yesterday = getYesterdayString()

	-- Update streak
	if data.lastDailyClaimDate == yesterday then
		data.dailyStreak = data.dailyStreak + 1
	else
		data.dailyStreak = 1
	end

	data.lastDailyClaimDate = today

	-- Get reward for this day (cycle through the table)
	local rewardIndex = ((data.dailyStreak - 1) % #Config.DAILY_REWARDS) + 1
	local reward = Config.DAILY_REWARDS[rewardIndex]

	-- Award currency
	if reward.currency and reward.currency > 0 then
		CurrencySystem.addCurrency(player, reward.currency)
	end

	return true, {
		day = data.dailyStreak,
		rewardIndex = rewardIndex,
		currency = reward.currency or 0,
	}
end

return DailyRewardSystem

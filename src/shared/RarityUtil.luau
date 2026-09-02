--[[
	RarityUtil.luau — Weighted-random helper for hatch tier rolls.
	Pure functions with no side effects. Usable on both server (rolls)
	and client (odds-disclosure display).
]]

local Config = require(script.Parent.Config)

local RarityUtil = {}

--- Apply luck bonus to the base hatch weights and return a normalized table.
--- Higher luck shifts weight toward higher tiers.
--- Formula: effective_weight[tier] = base * (1 + luck * LUCK_TIER_MULTIPLIER * tier)
--- @param luckBonus number — the player's effective luck value (≥ 1)
--- @return { [number]: number } — tier → probability (0..1), sums to 1
function RarityUtil.getEffectiveWeights(luckBonus: number): { [number]: number }
	local weights = {}
	local total = 0

	for tier, baseWeight in pairs(Config.HATCH_WEIGHTS) do
		local effective = baseWeight * (1 + (luckBonus - 1) * Config.LUCK_TIER_MULTIPLIER * tier)
		-- Clamp to avoid negative weights if config is mis-tuned
		effective = math.max(effective, 0)
		weights[tier] = effective
		total = total + effective
	end

	-- Normalize to probabilities
	if total > 0 then
		for tier, w in pairs(weights) do
			weights[tier] = w / total
		end
	end

	return weights
end

--- Roll a random starting tier for a hatched egg, respecting luck.
--- @param luckBonus number — the player's effective luck value (≥ 1)
--- @return number — the rolled tier index
function RarityUtil.rollTier(luckBonus: number): number
	local weights = RarityUtil.getEffectiveWeights(luckBonus)

	-- Build a sorted list of (tier, probability) for stable iteration
	local sorted = {}
	for tier, prob in pairs(weights) do
		table.insert(sorted, { tier = tier, prob = prob })
	end
	table.sort(sorted, function(a, b)
		return a.tier < b.tier
	end)

	-- Cumulative distribution sample
	local roll = math.random()
	local cumulative = 0
	for _, entry in ipairs(sorted) do
		cumulative = cumulative + entry.prob
		if roll <= cumulative then
			return entry.tier
		end
	end

	-- Fallback (should not happen with correct weights)
	return sorted[#sorted].tier
end

--- Roll a tier that is guaranteed to be at least `minTier`.
--- Used for session rewards that promise a minimum starting tier.
--- @param luckBonus number
--- @param minTier number
--- @return number
function RarityUtil.rollTierWithFloor(luckBonus: number, minTier: number): number
	local tier = RarityUtil.rollTier(luckBonus)
	return math.max(tier, minTier)
end

return RarityUtil

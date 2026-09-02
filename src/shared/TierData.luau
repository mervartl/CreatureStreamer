--[[
	TierData.luau — Maps tier index (0–19) to display info.
	The tier scale unifies "rarity" and "level" into a single integer.
	  Tier 0–4   = Common  L1–L5
	  Tier 5–9   = Rare    L1–L5
	  Tier 10–14 = Epic    L1–L5
	  Tier 15–19 = Legendary L1–L5
]]

local Config = require(script.Parent.Config)

local TierData = {}

-- Rarity colors for placeholder Part coloring (BrickColor-friendly RGB)
local RARITY_COLORS = {
	Common    = Color3.fromRGB(180, 180, 180),  -- grey
	Rare      = Color3.fromRGB(70,  130, 230),  -- blue
	Epic      = Color3.fromRGB(170, 60,  220),  -- purple
	Legendary = Color3.fromRGB(255, 180, 30),   -- gold
}

-- Build the lookup table once at require time
local entries = {}

for tier = 0, Config.TIER_MAX do
	local rarityIndex = math.floor(tier / Config.LEVELS_PER_RARITY) + 1
	local levelInRarity = (tier % Config.LEVELS_PER_RARITY) + 1
	local rarityName = Config.RARITY_NAMES[rarityIndex] or "Unknown"

	entries[tier] = {
		tier = tier,
		rarityName = rarityName,
		level = levelInRarity,
		displayName = rarityName .. " L" .. tostring(levelInRarity),
		color = RARITY_COLORS[rarityName] or Color3.fromRGB(255, 255, 255),
	}
end

--- Get the full info table for a tier index.
--- @param tier number — integer 0..TIER_MAX
--- @return { tier: number, rarityName: string, level: number, displayName: string, color: Color3 }
function TierData.get(tier: number)
	return entries[tier]
end

--- Get just the display name string (e.g. "Rare L3").
function TierData.getDisplayName(tier: number): string
	local entry = entries[tier]
	return if entry then entry.displayName else ("T" .. tostring(tier))
end

--- Get the rarity color for a tier.
function TierData.getColor(tier: number): Color3
	local entry = entries[tier]
	return if entry then entry.color else Color3.fromRGB(255, 255, 255)
end

--- Get the rarity name for a tier.
function TierData.getRarityName(tier: number): string
	local entry = entries[tier]
	return if entry then entry.rarityName else "Unknown"
end

--- Get all entries (for iteration, e.g. in odds display).
function TierData.getAll()
	return entries
end

return TierData

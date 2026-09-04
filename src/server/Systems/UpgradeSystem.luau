--[[
	UpgradeSystem.luau — Handles purchasing currency-based upgrades (Ceiling, Floor).
]]

local Config = require(game.ReplicatedStorage.Shared.Config)
local DataStoreManager = require(script.Parent.DataStoreManager)

local UpgradeSystem = {}

--- Calculate the price for the next ceiling upgrade.
function UpgradeSystem.getCeilingPrice(ceilingLevel: number): number
	local currentMaxTier = Config.BASE_MAX_HATCH_TIER + ceilingLevel
	return Config.getCumulativeMergeCost(currentMaxTier) * Config.CEILING_UPGRADE_MULTIPLIER
end

--- Calculate the price for the next floor upgrade.
function UpgradeSystem.getFloorPrice(floorLevel: number): number
	local rawCost = Config.FLOOR_UPGRADE_BASE_COST * (Config.FLOOR_UPGRADE_COST_SCALE ^ floorLevel)
	return math.floor(rawCost / 100 + 0.5) * 100
end

--- Attempt to buy an upgrade.
--- @param player Player
--- @param upgradeType string — "ceiling" or "floor"
--- @return boolean, string — success, result/error
function UpgradeSystem.buyUpgrade(player: Player, upgradeType: string)
	local data = DataStoreManager.getData(player)
	if not data then
		return false, "Data not loaded"
	end

	if upgradeType == "ceiling" then
		local currentMaxTier = Config.BASE_MAX_HATCH_TIER + data.ceilingLevel
		if currentMaxTier >= Config.TIER_MAX then
			return false, "Maximum ceiling level reached"
		end

		local price = UpgradeSystem.getCeilingPrice(data.ceilingLevel)
		if data.currency < price then
			return false, "Not enough currency"
		end

		data.currency = data.currency - price
		data.ceilingLevel = data.ceilingLevel + 1
		return true, "Ceiling upgraded"

	elseif upgradeType == "floor" then
		local currentMaxTier = Config.BASE_MAX_HATCH_TIER + data.ceilingLevel
		local currentPoolSize = (currentMaxTier - data.floorLevel) + 1
		
		if currentPoolSize <= Config.MIN_TABLE_SIZE then
			return false, "Cannot narrow hatch pool further"
		end

		local price = UpgradeSystem.getFloorPrice(data.floorLevel)
		if data.currency < price then
			return false, "Not enough currency"
		end

		data.currency = data.currency - price
		data.floorLevel = data.floorLevel + 1
		return true, "Floor upgraded"
	end

	return false, "Invalid upgrade type"
end

return UpgradeSystem

--[[
	LuckSystem.luau — Aggregates base luck + gamepass + session boosts.
	Checks Game Pass ownership via MarketplaceService.
]]

local MarketplaceService = game:GetService("MarketplaceService")

local Config = require(game.ReplicatedStorage.Shared.Config)
local DataStoreManager = require(script.Parent.DataStoreManager)

local LuckSystem = {}

-- Cache of gamepass ownership checks (cleared on leave)
local passOwnershipCache = {}

--- Check if a player owns the 2x Luck Game Pass.
--- Caches result so we only call the API once per session.
--- @param player Player
--- @return boolean
function LuckSystem.checkLuckPass(player: Player): boolean
	if passOwnershipCache[player.UserId] ~= nil then
		return passOwnershipCache[player.UserId]
	end

	-- Skip check if the placeholder ID hasn't been replaced
	if Config.LUCK_GAMEPASS_ID == 0 then
		passOwnershipCache[player.UserId] = false
		return false
	end

	local success, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, Config.LUCK_GAMEPASS_ID)
	end)

	local result = success and owns or false
	passOwnershipCache[player.UserId] = result

	-- Also update the player data flag
	local data = DataStoreManager.getData(player)
	if data then
		data.hasLuckPass = result
	end

	return result
end

--- Called when a player purchases the luck pass mid-session.
function LuckSystem.onLuckPassPurchased(player: Player)
	passOwnershipCache[player.UserId] = true
	local data = DataStoreManager.getData(player)
	if data then
		data.hasLuckPass = true
	end
end

--- Get the player's effective luck value (base × pass × session boosts).
--- @param player Player
--- @return number — effective luck multiplier (≥ 1)
function LuckSystem.getEffectiveLuck(player: Player): number
	local data = DataStoreManager.getData(player)
	if not data then
		return Config.BASE_LUCK
	end

	local baseLuck = data.luck or Config.BASE_LUCK
	local sessionBoost = data.sessionLuckBoost or 0

	-- Apply gamepass multiplier
	if data.hasLuckPass then
		baseLuck = baseLuck * Config.LUCK_PASS_MULTIPLIER
	end

	-- Apply session luck boost (additive on top of multiplied base)
	return baseLuck + sessionBoost
end

--- Clear cache when a player leaves.
function LuckSystem.clearCache(player: Player)
	passOwnershipCache[player.UserId] = nil
end

return LuckSystem

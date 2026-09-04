--[[
	HatchSystem.luau — Server-side egg hatching logic.
	Validates currency, rolls tier, adds egg to inventory.
]]

local HttpService = game:GetService("HttpService")

local Config = require(game.ReplicatedStorage.Shared.Config)
local RarityUtil = require(game.ReplicatedStorage.Shared.RarityUtil)
local DataStoreManager = require(script.Parent.DataStoreManager)
local LuckSystem = require(script.Parent.LuckSystem)

local HatchSystem = {}

--- Attempt to hatch a new egg for the player.
--- @param player Player
--- @return boolean success, table|string result — the new egg table or error message
function HatchSystem.hatch(player: Player)
	local data = DataStoreManager.getData(player)
	if not data then
		return false, "Data not loaded"
	end

	-- Check currency
	if data.currency < Config.HATCH_COST then
		return false, "Not enough currency"
	end

	-- Check egg inventory cap
	if #data.eggs >= data.eggSlotsCap then
		return false, "Egg inventory full"
	end

	-- Deduct cost
	data.currency = data.currency - Config.HATCH_COST

	-- Roll starting tier using player's effective luck, ceiling, and floor
	local luck = LuckSystem.getEffectiveLuck(player)
	local tier = RarityUtil.rollTier(luck, data.ceilingLevel, data.floorLevel)

	-- Create the egg
	local newEgg = {
		tier = tier,
		id = HttpService:GenerateGUID(false),
	}

	table.insert(data.eggs, newEgg)

	return true, newEgg
end

return HatchSystem

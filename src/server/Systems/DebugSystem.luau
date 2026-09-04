--[[
	DebugSystem.luau — Developer debug chat commands.
]]

local HttpService = game:GetService("HttpService")

local Config = require(game.ReplicatedStorage.Shared.Config)
local RarityUtil = require(game.ReplicatedStorage.Shared.RarityUtil)
local DataStoreManager = require(script.Parent.DataStoreManager)

local DebugSystem = {}

--- Parse and execute a chat command if the player is authorized.
function DebugSystem.handleChat(player: Player, message: string, syncCallback: (Player) -> ())
	-- Check authorization
	if not Config.DEBUG_USER_IDS[player.UserId] then
		return
	end

	-- Simple command parsing
	local args = string.split(message, " ")
	local command = string.lower(args[1])

	if command == "/addcurrency" then
		local amount = tonumber(args[2])
		if amount then
			local data = DataStoreManager.getData(player)
			if data then
				data.currency = data.currency + amount
				print("[Debug] Added " .. amount .. " currency to " .. player.Name)
				syncCallback(player)
			end
		end

	elseif command == "/addeggs" then
		local tier = tonumber(args[2])
		local count = tonumber(args[3]) or 1
		
		if tier and tier >= 0 and tier <= Config.TIER_MAX then
			local data = DataStoreManager.getData(player)
			if data then
				for i = 1, count do
					if #data.eggs < data.eggSlotsCap then
						table.insert(data.eggs, {
							id = HttpService:GenerateGUID(false),
							tier = tier
						})
					else
						print("[Debug] Cannot add more eggs, inventory full!")
						break
					end
				end
				print("[Debug] Added " .. count .. "x tier " .. tier .. " eggs to " .. player.Name)
				syncCallback(player)
			end
		end

	elseif command == "/printodds" then
		local data = DataStoreManager.getData(player)
		if data then
			local luck = data.luck or Config.BASE_LUCK
			if data.hasLuckPass then
				luck = luck * Config.LUCK_PASS_MULTIPLIER
			end
			luck = luck + (data.sessionLuckBoost or 0)
			
			local ceilingLevel = data.ceilingLevel or 0
			local floorLevel = data.floorLevel or 0
			
			print("\n--- [Debug] HATCH ODDS FOR: " .. player.Name .. " ---")
			print("Luck: " .. luck .. "x | Ceiling: +" .. ceilingLevel .. " | Floor: +" .. floorLevel)
			print(string.format("%-8s | %-8s | %-10s | %-10s | %-10s | %-8s", "Tier", "Source", "Base Wt", "Luck Mult", "Luck Wt", "Final %"))
			
			local minTier = floorLevel
			local maxTier = Config.BASE_MAX_HATCH_TIER + ceilingLevel
			
			local finalWeights = RarityUtil.getEffectiveWeights(luck, ceilingLevel, floorLevel)
			
			for tier = minTier, maxTier do
				local source = (tier <= Config.BASE_MAX_HATCH_TIER) and "Base" or "Ceiling"
				local baseWt = Config.HATCH_WEIGHTS[tier] or 0
				local luckMult = 1 + (luck - 1) * Config.LUCK_TIER_MULTIPLIER * tier
				local luckWt = baseWt * luckMult
				local finalPct = (finalWeights[tier] or 0) * 100
				print(string.format("Tier %-3d | %-8s | %-10.4f | %-10.2fx | %-10.4f | %6.2f%%", tier, source, baseWt, luckMult, luckWt, finalPct))
			end
			print("------------------------------------------\n")
		end
	end
end

--- Initialize listener for a player
function DebugSystem.init(player: Player, syncCallback: (Player) -> ())
	player.Chatted:Connect(function(message)
		DebugSystem.handleChat(player, message, syncCallback)
	end)
end

return DebugSystem

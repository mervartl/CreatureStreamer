--[[
	MarketplaceHandler.luau — Handles Game Pass and Developer Product purchases.
	Sets up ProcessReceipt callback and PromptGamePassPurchaseFinished listener.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Config = require(game.ReplicatedStorage.Shared.Config)
local DataStoreManager = require(script.Parent.DataStoreManager)
local CurrencySystem = require(script.Parent.CurrencySystem)
local LuckSystem = require(script.Parent.LuckSystem)
local SessionRewardSystem = require(script.Parent.SessionRewardSystem)

local MarketplaceHandler = {}

--- Initialize all marketplace listeners. Call once from server bootstrap.
function MarketplaceHandler.init()
	-- Handle Developer Product purchases (repeatable)
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then
			-- Player left before receipt processed — don't grant, will retry
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local data = DataStoreManager.getData(player)
		if not data then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local productId = receiptInfo.ProductId

		if productId == Config.VIEWERS_PACK_PRODUCT_ID then
			-- Viewers Pack: instant currency injection
			CurrencySystem.addCurrency(player, Config.VIEWERS_PACK_AMOUNT)
			-- Sync to client
			local SyncPlayerData = game.ReplicatedStorage.Remotes:FindFirstChild("SyncPlayerData")
			if SyncPlayerData then
				SyncPlayerData:FireClient(player, DataStoreManager.getClientData(player))
			end
			return Enum.ProductPurchaseDecision.PurchaseGranted

		elseif productId == Config.INSTANT_CLAIM_PRODUCT_ID then
			-- Instant Claim: skip session timer — mark all elapsed milestones as claimable
			-- We do this by setting sessionStartTime far enough back
			local longestMilestone = 0
			for _, milestone in ipairs(Config.SESSION_MILESTONES) do
				if milestone.time > longestMilestone then
					longestMilestone = milestone.time
				end
			end
			data.sessionStartTime = os.clock() - longestMilestone - 1

			-- Sync to client
			local SyncPlayerData = game.ReplicatedStorage.Remotes:FindFirstChild("SyncPlayerData")
			if SyncPlayerData then
				SyncPlayerData:FireClient(player, DataStoreManager.getClientData(player))
			end
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		-- Unknown product
		warn("[MarketplaceHandler] Unknown product ID: " .. tostring(productId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Handle Game Pass purchase completion (one-time)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		if not wasPurchased then
			return
		end

		if gamePassId == Config.LUCK_GAMEPASS_ID then
			LuckSystem.onLuckPassPurchased(player)

			-- Sync to client
			local SyncPlayerData = game.ReplicatedStorage.Remotes:FindFirstChild("SyncPlayerData")
			if SyncPlayerData then
				SyncPlayerData:FireClient(player, DataStoreManager.getClientData(player))
			end
		end
	end)
end

return MarketplaceHandler

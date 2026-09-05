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

		local purchaseId = receiptInfo.PurchaseId
		-- Idempotency check: if already processed, return Granted immediately
		if data.purchaseHistory[purchaseId] then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		local productId = receiptInfo.ProductId
		local granted = false

		-- Viewers Pack: instant currency injection
		for _, pack in pairs(Config.VIEWERS_PACK_PRODUCTS) do
			if productId == pack.id then
				CurrencySystem.addCurrency(player, pack.amount)
				granted = true
				break
			end
		end

		-- Instant Claim: skip the currently pending session timer
		if productId == Config.INSTANT_CLAIM_PRODUCT_ID then
			local pendingMilestone = nil
			for i, milestone in ipairs(Config.SESSION_MILESTONES) do
				if not data.sessionRewardsClaimed[i] then
					pendingMilestone = milestone
					break
				end
			end
			
			if pendingMilestone then
				-- Fast-forward sessionStartTime exactly to the pending milestone
				local timeNeeded = pendingMilestone.time
				data.sessionStartTime = workspace:GetServerTimeNow() - timeNeeded
				granted = true
			else
				-- If no pending milestone, it means all are claimed.
				-- We should ideally prevent purchase, but if it happens, we grant it.
				granted = true
			end
		end

		if not granted then
			warn("[MarketplaceHandler] Unknown product ID: " .. tostring(productId))
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		-- Mark as granted in history
		data.purchaseHistory[purchaseId] = true

		-- Force a synchronous save to ensure idempotency across crashes
		local saveSuccess = DataStoreManager.savePlayerData(player)
		if not saveSuccess then
			-- If saving failed, revert the local idempotency state (currency remains locally for the session, 
			-- but we let Roblox retry later. Or if we want strict safety, we don't grant locally until save succeeds.
			-- Given Roblox's nature, best to let it retry).
			data.purchaseHistory[purchaseId] = nil
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		-- Sync to client after successful save
		local SyncPlayerData = game.ReplicatedStorage.Remotes:FindFirstChild("SyncPlayerData")
		if SyncPlayerData then
			SyncPlayerData:FireClient(player, DataStoreManager.getClientData(player))
		end

		return Enum.ProductPurchaseDecision.PurchaseGranted
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

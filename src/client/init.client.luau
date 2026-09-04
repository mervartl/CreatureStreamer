--[[
	Client Bootstrap — init.client.luau
	Listens for SyncPlayerData events, maintains local state mirror,
	and initializes all UI screen modules.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SyncPlayerDataRemote = Remotes:WaitForChild("SyncPlayerData")

-- Shared modules (available client-side)
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

--------------------------------------------------------------------------------
-- Client State — read-only mirror of server data
--------------------------------------------------------------------------------
local ClientState = {
	data = nil,                -- populated by SyncPlayerData
	onDataChanged = {},        -- array of callback functions
}

--- Register a callback that fires whenever player data updates.
function ClientState.onChange(callback)
	table.insert(ClientState.onDataChanged, callback)
	-- Fire immediately if data already exists
	if ClientState.data then
		task.spawn(callback, ClientState.data)
	end
end

--- Get the current data (may be nil before first sync).
function ClientState.getData()
	return ClientState.data
end

-- Listen for state updates from server
SyncPlayerDataRemote.OnClientEvent:Connect(function(newData)
	ClientState.data = newData
	for _, callback in ipairs(ClientState.onDataChanged) do
		task.spawn(callback, newData)
	end
end)

--------------------------------------------------------------------------------
-- Make ClientState available to UI modules via a ModuleScript-like pattern.
-- UI scripts require this file and get the ClientState table.
-- Since init.client.luau is a LocalScript (not a ModuleScript), we store
-- ClientState in a shared location that UI scripts can access.
--------------------------------------------------------------------------------

-- Store ClientState in an attribute-accessible location for the UI scripts
-- We use a BindableEvent approach: fire data to all listeners
local stateFolder = Instance.new("Folder")
stateFolder.Name = "ClientState"
stateFolder.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Store the state table reference on the folder for direct access
local stateValue = Instance.new("ObjectValue")
stateValue.Name = "StateRef"
stateValue.Parent = stateFolder

-- Create a BindableEvent for notifying UI modules of data changes
local dataChangedEvent = Instance.new("BindableEvent")
dataChangedEvent.Name = "DataChanged"
dataChangedEvent.Parent = stateFolder

-- Create a BindableFunction so UI modules can actively pull current data
local getStateFunc = Instance.new("BindableFunction")
getStateFunc.Name = "GetState"
getStateFunc.OnInvoke = function()
	return ClientState.data
end
getStateFunc.Parent = stateFolder

-- Forward SyncPlayerData to the BindableEvent so GUI scripts can listen
SyncPlayerDataRemote.OnClientEvent:Connect(function(newData)
	ClientState.data = newData
	dataChangedEvent:Fire(newData)
end)

-- Store Remotes reference for easy access by UI scripts
local remotesRef = Instance.new("ObjectValue")
remotesRef.Name = "RemotesRef"
remotesRef.Value = Remotes
remotesRef.Parent = stateFolder

print("[Client] Creature Streamer client initialized, requesting initial server data...")

-- Explicitly request data once UI is hooked up to avoid race condition
task.spawn(function()
	local RequestSyncRemote = Remotes:WaitForChild("RequestSync")
	local initialData = RequestSyncRemote:InvokeServer()
	if initialData then
		ClientState.data = initialData
		dataChangedEvent:Fire(initialData)
	end
end)

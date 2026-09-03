local ScreenManager = {}

local BindableEvent = Instance.new("BindableEvent")
ScreenManager.ScreenChanged = BindableEvent.Event

ScreenManager.CurrentClass = "Tablet"
ScreenManager.CurrentScale = 1.0

local function updateScreen()
	local camera = workspace.CurrentCamera
	if not camera then return end
	
	local viewport = camera.ViewportSize
	local x = viewport.X
	local y = viewport.Y
	if x <= 0 or y <= 0 then return end
	
	if x <= 960 then
		ScreenManager.CurrentClass = "Mobile"
		-- Base height 400 for Mobile
		local rawScale = y / 400
		ScreenManager.CurrentScale = math.clamp(rawScale, 0.75, 1.25)
	elseif x <= 1200 then
		ScreenManager.CurrentClass = "Tablet"
		-- Base height 800 for Tablet
		local rawScale = y / 800
		ScreenManager.CurrentScale = math.clamp(rawScale, 0.75, 1.25)
	else
		ScreenManager.CurrentClass = "PC"
		-- Base height 800 for PC
		local rawScale = y / 800
		ScreenManager.CurrentScale = math.clamp(rawScale, 0.75, 1.25)
	end
	
	BindableEvent:Fire({
		deviceClass = ScreenManager.CurrentClass,
		scale = ScreenManager.CurrentScale
	})
end

-- Hook to camera
task.spawn(function()
	while not workspace.CurrentCamera do
		task.wait(0.1)
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScreen)
	updateScreen()
end)

return ScreenManager

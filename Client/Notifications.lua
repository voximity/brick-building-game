local load = require(game:GetService("ReplicatedStorage").Shared.Load)(script)
---------------------------------------------------------------------------------
local network = load("/Shared/Network")

local n = {}

n.play = function(parent, sound, repetitions, delays)
	local s = sound:Clone()
	s.Parent = parent
	
	spawn(function()
		for i = 1, (repetitions or 1) do
			s:Stop()
			s:Play()
			wait(delays or 0)
		end
		
		s:Destroy()
	end)
end

n.init = function()
	local gui = Instance.new("ScreenGui")
	gui.Name = "NotificationGui"
	n.gui = gui
	
	return gui
end


n.show = function(message, isError)
	n.gui:ClearAllChildren()
	
	if isError then
		n.play(n.gui, script.Error, 2, 1 / 7.5)
	end
	
	local color = isError and Color3.new(1, 0, 0) or Color3.new(0, 0.7, 1)
	
	local f = script.Notification:Clone()
	
	local fontSize, font, frameSize = f.TextLabel.TextSize, f.TextLabel.Font, Vector2.new(300, math.huge)
	local textSize = game:GetService("TextService"):GetTextSize(message, fontSize, font, frameSize)
	
	f.Accent.BackgroundColor3 = color
	f.TextLabel.Text = message
	f.Size = UDim2.new(0, textSize.X + 10, 0, math.ceil(textSize.Y / fontSize) * fontSize + 10)
	local pos = UDim2.new(0.5, -f.Size.X.Offset / 2, 0.7, 0)
	f.Parent = n.gui
	
	f.Position = pos
	
	if isError then
		spawn(function()
			local x
			local times = 30
			for i = 1, times do
				x = math.sin(i / times * math.pi * 2) * 12
				f.Position = pos + UDim2.new(0, x, 0, 0)
				
				game:GetService("RunService").RenderStepped:wait()
			end
			f.Position = pos
		end)
	end
	
	delay(5, function()
		if f.Parent ~= nil then
			f:Destroy()
		end
	end)
end

network.on("message", n.show)

return n
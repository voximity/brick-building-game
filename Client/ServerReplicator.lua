local load = require(game:GetService("ReplicatedStorage").Shared.Load)(script)
---------------------------------------------------------------------------------
local bg, big = load("/Shared/BrickGenerator"), load("../BrickIconGenerator")
local net = load("/Shared/Network")

local tween = game:GetService("TweenService")

local sr = {}

net.on("brick color", function(brick, color)
	local twinf = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
	for i,v in next, brick:GetChildren() do
		if v:IsA("BasePart") then
			local t = tween:Create(v, twinf, {
				Color = color.color3,
				Transparency = color.trans
			})
			t:Play()
			delay(0.3, function()
				v.Color = color.color3
				v.Material = color.material
				v.Transparency = color.trans
			end)
		end
	end
end)

spawn(function()
	while wait(0.1) do
		local c = workspace.CurrentCamera
		
		net.send("camera angle", c.CFrame)
	end
end)

return sr
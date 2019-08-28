local load = require(game:GetService("ReplicatedStorage").Shared.Load)(script)
---------------------------------------------------------------------------------
local bg = load("/Shared/BrickGenerator")
local ms = load("/Shared/MenuSound")
local kb = load("../Keyboard")
local network = load("/Shared/Network")
local me = game.Players.LocalPlayer
local assets = game:GetService("ReplicatedStorage").Assets

local fig = {}

fig.weld = function(p0, p1, c0, c1)
	p1.Anchored = false
	p1.CanCollide = false
	
	local weld = Instance.new("Weld")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.C0 = c0 or CFrame.new()
	weld.C1 = c1 or CFrame.new()
	weld.Parent = p0
	
	return weld
end

fig.speed = function(p)
	return (p.Velocity * Vector3.new(1, 0, 1)).magnitude
end

function lerp(a, b, c) return a + (b - a) * c end

fig.camAngles = {}
fig.playerEquips = {}

network.on("camera angle", function(player, cframe)
	if player == me then return end
	fig.camAngles[player.Name] = CFrame.Angles(math.asin(cframe.lookVector.Y), 0, 0)
end)

network.on("equip", function(player, reference)
	if player == me then return end
	fig.playerEquips[player.Name] = reference
end)

network.on("unequip", function(player)
	if player == me then return end
	fig.playerEquips[player.Name] = nil
end)

fig.render = function(c)
	local model = assets.Minifig:Clone()
	model.Parent = c
	
	local lowerTorso = fig.weld(c.HumanoidRootPart, model.LowerTorso, CFrame.new(0, -0.8 - model.LowerTorso.Size.Y / 2, 0) * CFrame.Angles(0, math.pi, 0), CFrame.new())
	local root = fig.weld(model.LowerTorso, model.Torso,  CFrame.new(0, model.LowerTorso.Size.Y / 2, 0), CFrame.new(0, -model.Torso.Size.Y / 2, 0))
	local neck = fig.weld(model.Torso, model.Head, CFrame.new(0, model.Torso.Size.Y / 2, 0), CFrame.new(0, -model.Head.Size.Y / 2, 0))
	
	local leftShoulder = fig.weld(model.Torso, model.LeftShoulder, CFrame.new(model.Torso.Size.X / 2 + model.LeftShoulder.Size.X / 2, 0.5, 0))
	local rightShoulder = fig.weld(model.Torso, model.RightShoulder, CFrame.new(-model.Torso.Size.X / 2 - model.RightShoulder.Size.X / 2, 0.5, 0))
	
	local leftHand = fig.weld(model.LeftShoulder, model.LeftHand, CFrame.new(), (CFrame.new(0.3, -1.5, 0) * CFrame.Angles(math.pi / 2, 0, 0)):inverse())
	local rightHand = fig.weld(model.RightShoulder, model.RightHand, CFrame.new(), (CFrame.new(-0.3, -1.5, 0) * CFrame.Angles(math.pi / 2, 0, 0)):inverse())
	
	local leftFoot = fig.weld(c.HumanoidRootPart, model.LeftFoot, CFrame.new(), (CFrame.new(0.5, -2.7, -0.5) * CFrame.Angles(0, math.pi, 0)):inverse())
	local rightFoot = fig.weld(c.HumanoidRootPart, model.RightFoot, CFrame.new(), (CFrame.new(-0.5, -2.7, -0.5) * CFrame.Angles(0, math.pi, 0)):inverse())
	
	local faceWeld = fig.weld(model.Head, model.Face, CFrame.new(0, 0.1, 0))
	
	local bui = model.NameLabel
	bui.Parent = model.Head
	bui.TextLabel.Text = c.Name
	
	local connection
	local t = 0
	local cspeed = 0
	local equipped
	
	local tangle = CFrame.new()
	local lastEquipped
	connection = game:GetService("RunService").RenderStepped:connect(function(d)
		if c.Parent == nil then connection:disconnect() end
		
		if fig.playerEquips[c.Name] and not lastEquipped then
			equipped = fig.playerEquips[c.Name]:Clone()
			equipped.PrimaryPart = equipped.Mount
			for i,v in next, equipped:GetChildren() do
				if v:IsA("BasePart") then
					v.Anchored = true
					v.CanCollide = false
				end
			end
			equipped.Parent = c
		elseif fig.playerEquips[c.Name] ~= lastEquipped then
			equipped:Destroy()
			equipped = nil
		elseif not fig.playerEquips[c.Name] and lastEquipped then
			equipped:Destroy()
			equipped = nil
		end
		
		for i,v in next, c:GetChildren() do
			if v:IsA("BasePart") then
				v.Transparency = 1
			end
			
			if v:IsA("Accessory") then
				v:Destroy()
			elseif v:FindFirstChild("face") then
				v.face:Destroy()
			elseif v:FindFirstChild("roblox") then
				v.roblox:Destroy()
			end
		end
		
		lastEquipped = equipped and fig.playerEquips[c.Name] or nil
		
		local speed = fig.speed(c.HumanoidRootPart)
		t = t + d * speed / 16
		cspeed = lerp(cspeed, speed, 0.2)
		tangle = tangle:lerp(fig.camAngles[c.Name] or CFrame.new(), 0.3)
		
		local arm = math.sin(t * 10) * 45 * cspeed / 16
		local leg = math.sin(t * 10) * 52 * cspeed / 16
		
		lowerTorso.C1 = tangle
		
		leftShoulder.C1 = CFrame.Angles(math.rad(20 - arm), 0, 0)
		rightShoulder.C1 = CFrame.Angles(math.rad(equipped and 90 or 20 + arm), 0, 0)
		
		leftFoot.C0 = CFrame.Angles(math.rad(-leg), 0, 0)
		rightFoot.C0 = CFrame.Angles(math.rad(leg), 0, 0)
		
		if equipped then
			equipped:SetPrimaryPartCFrame(model.RightHand.CFrame)
		end
	end)
end

fig.setupPlayer = function(p)
	p.CharacterAdded:connect(function(c)
		wait(2.5)
		fig.render(c)
	end)
end

for i,v in next, game.Players:GetPlayers() do
	if v ~= me then
		fig.setupPlayer(v)
		fig.render(v.Character)
	end
end

game.Players.PlayerAdded:connect(function(p)
	fig.setupPlayer(p)
end)

return fig
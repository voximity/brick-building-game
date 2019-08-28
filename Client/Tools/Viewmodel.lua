local load = require(game:GetService("ReplicatedStorage").Shared.Load)(script)
---------------------------------------------------------------------------------
local ms = load("/Shared/MenuSound")
local kb = load("../Keyboard")
local network = load("/Shared/Network")

local assets = game:GetService("ReplicatedStorage").Assets

function lerp(a, b, c) return a + (b - a) * c end

local vm = {}

vm.camera = workspace.CurrentCamera
vm.current = {}

vm.stop = function(nosend)
	if vm.current.model then
		vm.current.model:Destroy()
	end
	
	if not nosend then
		network.send("unequip")
	end
	
	vm.current = {
		model = nil,
		rhand = nil,
		upward = 120,
		tupward = 0
	}
end
vm.create = function(source)
	vm.stop(true)
	
	network.send("equip", source)
	
	local model = source:Clone()
	local mount = model:FindFirstChild("Mount")
	model.PrimaryPart = mount
	
	local rightHand = assets.Hands.RightHand:Clone()
	rightHand.Parent = model
	rightHand.CFrame = model.PrimaryPart.CFrame
	
	model.Parent = vm.camera
	vm.current.model = model
	vm.current.rhand = rightHand
end

vm.delta = {
	x = 0,
	y = 0,
	sway = CFrame.new(),
	rotsway = CFrame.new(),
	framesince = false
}

vm.horVel = function(part)
	return (part.Velocity * Vector3.new(1, 0, 1)).magnitude
end
vm.vertVel = function(part)
	return part.Velocity.Y
end

vm.anim = {}
vm.anim.data = {}
vm.anim.pos = CFrame.new()
vm.anim.angle = CFrame.new()
vm.anim.stop = false

local animPos = CFrame.new()
local animAngle = CFrame.new()

vm.playAnimation = function(anim)
	spawn(function()
		if vm.anim.playing then
			vm.anim.stop = true
			repeat
				game:GetService("RunService").RenderStepped:wait()
			until not vm.anim.playing
		end
		
		vm.anim.playing = true
		vm.anim.data = anim
		vm.anim.pos = CFrame.new()
		vm.anim.angle = CFrame.new()
		animPos = CFrame.new()
		animAngle = CFrame.new()
		vm.anim.stop = false
		
		for i,v in next, anim do
			local lastpos = vm.anim.pos
			local lastangle = vm.anim.angle
			
			local t = time()
			repeat
				if vm.anim.stop then
					break
				end
				local i = (time() - t) / v.duration
				vm.anim.pos = lastpos:lerp(v.pos, i)
				vm.anim.angle = lastangle:lerp(v.angle, i)
				game:GetService("RunService").RenderStepped:wait()
				if vm.anim.stop then
					break
				end
			until time() >= t + v.duration
			
			lastpos = v.pos
			lastangle = v.angle
			if vm.anim.stop then
				break
			end
		end
		
		vm.anim.playing = false
		vm.anim.pos = CFrame.new()
		vm.anim.angle = CFrame.new()
	end)
end

game:GetService("UserInputService").InputChanged:connect(function(io)
	if io.UserInputType == Enum.UserInputType.MouseMovement then
		vm.delta.x, vm.delta.y = io.Delta.X, io.Delta.Y
		vm.delta.framesince = false
	end
end)

local cbob = CFrame.new()
local cvbob = 0
local hspeed = 0
local n = 0

game:GetService("RunService").RenderStepped:connect(function(delta)
	if vm.current.model then
		
		local model = vm.current.model
		
		local char = game.Players.LocalPlayer.Character
		hspeed = lerp(hspeed, vm.horVel(char.HumanoidRootPart), 0.15)
		local vspeed = vm.vertVel(char.HumanoidRootPart)
		
		local bob = CFrame.new()
		n = n + delta * hspeed / 16
		bob = CFrame.new(math.sin(n * 8.5) * 0.28, math.cos(n * 17 + math.pi) * 0.16, 0)
		
		cbob = cbob:lerp(bob, 0.1)
		cvbob = lerp(cvbob, vspeed / 6, 0.1)
		
		animPos = animPos:lerp(vm.anim.pos, 0.4)
		animAngle = animAngle:lerp(vm.anim.angle, 0.4)
		
		local origin = 
			vm.delta.sway
			* CFrame.new(1.5, -1.2, 0)
			* CFrame.Angles(math.rad(vm.current.upward - math.max(math.min(cvbob, 12), -12)), 0, 0)
			* CFrame.new(0, 0, -2.3)
			* CFrame.Angles(0, math.pi, 0)
			* animPos
			* animAngle
			* cbob
			* vm.delta.rotsway
		vm.current.upward = lerp(vm.current.upward, vm.current.tupward, 0.15)
		
		vm.delta.sway = vm.delta.sway:lerp(CFrame.Angles(math.rad(vm.delta.y / 2), math.rad(vm.delta.x / 2), 0), 0.15)		
		vm.delta.rotsway = vm.delta.rotsway:lerp(CFrame.Angles(math.rad(vm.delta.y / 2 * 0.75), math.rad(-vm.delta.x * 0.75), 0), 0.15)
		if vm.delta.framesince then
			vm.delta.x = 0
			vm.delta.y = 0
		end
		vm.delta.framesince = true
		
		model:SetPrimaryPartCFrame(vm.camera.CFrame * origin)
		
	end
end)

return vm
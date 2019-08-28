local load = require(game:GetService("ReplicatedStorage").Shared.Load)(script)
---------------------------------------------------------------------------------
local bg, big = load("/Shared/BrickGenerator"), load("../../BrickIconGenerator")
local ms = load("/Shared/MenuSound")
local kb = load("../../Keyboard")
local network = load("/Shared/Network")

local assets = game:GetService("ReplicatedStorage").Assets

local tool = {}
tool.tools = {}

tool.active = false

tool.viewmodel = function()
	return tool.tools.vm
end

tool.open = function()
	if tool.tools.freecam.active then return end
	if tool.tools.build.dragging then return end
	tool.active = true
	tool.tools.paint.close()
	tool.tools.build.close()
	tool.tools.save.close()
	tool.tools.wrench.close()
	tool.viewmodel().create(assets.Tools.RemoveTool)
end

tool.close = function()
	if tool.active then
		tool.viewmodel().stop()
	end
	tool.active = false
end

function getIntersectingVertical(rawSize, pos, factor, ignore)
	local off = Vector3.new(0.1, 0, 0.1)
	--local region3 = Region3.new(pos - ((rawSize - off) / 2 * Vector3.new(1, 0, 1)) + factor * Vector3.new(0, rawSize.Y / 2, 0), pos + (rawSize / 2 * Vector3.new(1, 0, 1) - off) + factor * Vector3.new(0, rawSize.Y / 2 + 0.1, 0))--Region3.new(pos - rawSize / 2 + Vector3.new(0, rawSize.Y * factor, 0) + off, pos + rawSize / 2 + Vector3.new(0, rawSize.Y * factor, 0) - off)
	local a = pos - ((rawSize - off) / 2 * Vector3.new(1, 0, 1)) + Vector3.new(0, rawSize.Y / 2, 0) * factor
	local b = pos + ((rawSize - off) / 2 * Vector3.new(1, 0, 1)) + Vector3.new(0, rawSize.Y / 2 + 0.1, 0) * factor
	
	local min = math.min
	local max = math.max
	
	local region3 = Region3.new(
		Vector3.new(min(a.X, b.X), min(a.Y, b.Y), min(a.Z, b.Z)),
		Vector3.new(max(a.X, b.X), max(a.Y, b.Y), max(a.Z, b.Z))
	)
	
	local parts = workspace:FindPartsInRegion3WithIgnoreList(region3, ignore)
	table.sort(parts, function(a, b) return math.abs(pos.Y - a.Position.Y) < math.abs(pos.Y - b.Position.Y) end)
	
	return parts
end

local brickIsOkayAfterDelete = function(toDelete, brick)
	if not brick then return true end
	local _, ry, _ = brick:GetPrimaryPartCFrame():toEulerAnglesXYZ()
	local rot = math.abs(math.floor(ry / math.pi * 2 * 10))
	local rawSize = rot % 2 == 1 and Vector3.new(brick.PrimaryPart.Size.Z, brick.PrimaryPart.Size.Y, brick.PrimaryPart.Size.X) or brick.PrimaryPart.Size
	
	local top = getIntersectingVertical(rawSize, brick.PrimaryPart.Position, 1, {toDelete, brick})
	local bottom = getIntersectingVertical(rawSize, brick.PrimaryPart.Position, -1, {toDelete, brick})
	
	local function check(part)
		if part == workspace.Base then return true end
		local b = part.Parent
		local supported = b:FindFirstChild("Supported")
		if supported and supported.Value == toDelete then
			return false
		else
			local function recursive(p)
				local s = p:FindFirstChild("Supported")
				if p == workspace.Base then
					return true
				elseif not s then
					return false
				elseif s.Value == toDelete then
					return false
				elseif s == toDelete then
					return false
				elseif s.Value == b then
					return false
				elseif s.Value == workspace.Base then
					return true
				else
					return recursive(s.Value)
				end
			end
			
			return recursive(b)
		end
	end
	
	local goodTops, goodBottoms = {}, {}
	for i,v in next, top do
		if check(v) then
			table.insert(goodTops, v)
		end
	end
	for i,v in next, bottom do
		if check(v) then
			table.insert(goodBottoms, v)
		end
	end
	
	if #goodTops + #goodBottoms == 0 then return false end
	local best = goodBottoms[1] or goodTops[1]
	return best == workspace.Base and best or best.Parent
end

tool.sparkList = {}
tool.createSparks = function(pos, normal, noPlay)
	local part = Instance.new("Part", workspace)
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.CFrame = CFrame.new(pos, normal)
	part.Transparency = 1
	
	if not noPlay then ms.play(ms.hit(), part) end
	
	local sparks = script.Sparks:Clone()
	sparks.Parent = part
	sparks:Emit(math.random(5, 10))
	
	table.insert(tool.sparkList, part)
	
	delay(3, function() for i = #tool.sparkList, 1, -1 do if tool.sparkList[i] == part then table.remove(tool.sparkList, i) end end part:Destroy() end)
end

local input = game:GetService("UserInputService")

input.InputEnded:connect(function(io)
	local c = workspace.CurrentCamera
	if tool.active and io.UserInputType == Enum.UserInputType.MouseButton1 then
		--tool.viewmodel().current.upward = -25
		tool.viewmodel().playAnimation({
			{duration = 0.04, pos = CFrame.new(0, -1.3, 0), angle = CFrame.Angles(math.rad(45), 0, 0)},
			{duration = 0.25, pos = CFrame.new(0, 0, 0), angle = CFrame.Angles(0, 0, 0)},
		})
		
		local part, hit, normal = workspace:FindPartOnRayWithIgnoreList(
			Ray.new(c.CFrame.p, c.CFrame.lookVector * 15),
			{workspace.CurrentCamera, game.Players.LocalPlayer.Character, unpack(tool.sparkList)}
		)
		
		if part and part.Parent.Name == "Brick" and part.Parent:FindFirstChild("Owner") then
			if part.Parent.Owner.Value == game.Players.LocalPlayer then
				local canDelete = true
				for i,v in next, part.Parent:GetChildren() do
					if v.Name == "Supporting" then
						local best = brickIsOkayAfterDelete(part.Parent, v.Value)
						if not best then
							canDelete = false
							break
						end
					end
				end
				if canDelete then
					for i,v in next, part.Parent:GetChildren() do
						if v.Name == "Supporting" then
							local supporting = v.Value
							local best = brickIsOkayAfterDelete(part.Parent, v.Value)
							network.send("set supported", supporting, best)
							network.send("set supporting", best, supporting)
						end
					end
					tool.createSparks(hit, normal, true)
					network.send("brick remove", part.Parent)
				else
					tool.notification.show("You can't remove a brick that would cause another to float.", true)
					tool.createSparks(hit, normal)
				end
			else
				tool.notification.show("You can't remove one of " .. part.Parent.Owner.Value.Name .. "'s bricks.", true)
				tool.createSparks(hit, normal)
			end
		elseif part then
			tool.createSparks(hit, normal)
		end
	end
end)

kb.bind("q", function()
	if not tool.active then
		tool.open()
	else
		tool.close()
	end
end)

local phy = game:GetService("PhysicsService")
network.on("brick remove", function(cf, brickInfo, color)
	local brickInfo = bg.fixBrickInfo(brickInfo)
	local bc = bg.createStandardBrick(brickInfo, color)
	bc:SetPrimaryPartCFrame(cf)
	phy:SetPartCollisionGroup(bc.PrimaryPart, "Destroyed")
	local weldToCenter = function(part)
		local w = Instance.new("Weld")
		w.Part0 = bc.PrimaryPart
		w.Part1 = part
		w.C0 = bc.PrimaryPart.CFrame:inverse()
		w.C1 = part.CFrame:inverse()
		w.Parent = part
		return w
	end
	
	local toTween = {}
	for i,v in next, bc:GetChildren() do
		if v:IsA("BasePart") then
			v.CanCollide = false
			v.Anchored = false
			if v == bc.PrimaryPart then
				v.CanCollide = true
				if v.Transparency ~= 1 then
					table.insert(toTween, v)
					if v:FindFirstChild("TopTexture") then table.insert(toTween, v.TopTexture) end
				if v:FindFirstChild("BottomTexture") then table.insert(toTween, v.BottomTexture) end
				end
			else
				weldToCenter(v)
				v.Massless = true
				table.insert(toTween, v)
				if v:FindFirstChild("TopTexture") then table.insert(toTween, v.TopTexture) end
				if v:FindFirstChild("BottomTexture") then table.insert(toTween, v.BottomTexture) end
			end
		end
	end
	
	bc.Name = "Destroying"
	bc.PrimaryPart.Velocity = Vector3.new(math.random(-10, 10), math.random(0, 15), math.random(-10, 10))
	bc.PrimaryPart.RotVelocity = Vector3.new(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10))
	bc.Parent = workspace
	
	delay(0.5, function()
		local twi = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
		for i,v in next, toTween do
			local tween = game:GetService("TweenService"):Create(v, twi, {Transparency = 1})
			spawn(function() tween:Play() end)
		end
		wait(1)
		bc:Destroy()
	end)
end)

return tool
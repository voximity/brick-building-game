local g = {}

g.createIcon = function(brick, info)
	local brick = brick:Clone()
	local w, h, d = info.width, info.height, info.depth
	
	local gridTexture = Instance.new("Texture")
	gridTexture.Face = "Top"
	gridTexture.StudsPerTileU, gridTexture.StudsPerTileV = 1, 1
	gridTexture.Texture = "rbxgameasset://Images/preview_grid"
	local cornerTexture = Instance.new("Texture")
	cornerTexture.Face = "Top"
	cornerTexture.StudsPerTileU, cornerTexture.StudsPerTileV = 1, 1
	cornerTexture.Texture = "rbxgameasset://Images/preview_grid_corner"
	
	local o = brick:GetPrimaryPartCFrame() * CFrame.new(0, -h / 2 - 0.5, 0)
	
	local gridPart = function(c, r, l)
		local gp = Instance.new("Part")
		gridTexture:Clone().Parent = gp
		gp.Anchored = true
		gp.Size = Vector3.new(l, 1, 1)
		gp.CFrame = c * CFrame.Angles(0, r, 0)
		gp.Transparency = 1
		gp.Parent = brick
		return gp
	end
	
	local cornerPart = function(c, r)
		local gp = Instance.new("Part")
		cornerTexture:Clone().Parent = gp
		gp.Anchored = true
		gp.Size = Vector3.new(1, 1, 1)
		gp.CFrame = c * CFrame.Angles(0, r, 0)
		gp.Transparency = 1
		gp.Parent = brick
		return gp
	end
	
	local zpGrid = gridPart(o * CFrame.new(0, 0,  d / 2 + 0.5),     0,        w)
	local znGrid = gridPart(o * CFrame.new(0, 0, -d / 2 - 0.5),     math.pi, w)
	local xpGrid = gridPart(o * CFrame.new( w / 2 + 0.5, 0, 0),     math.pi / 2, d)
	local xnGrid = gridPart(o * CFrame.new(-w / 2 - 0.5, 0, 0), 3 * math.pi / 2, d)
	local zpxpCorner = cornerPart(o * CFrame.new( w / 2 + 0.5, 0,  d / 2 + 0.5),     math.pi / 2)
	local znxpCorner = cornerPart(o * CFrame.new( w / 2 + 0.5, 0, -d / 2 - 0.5),     math.pi)
	local znxnCorner = cornerPart(o * CFrame.new(-w / 2 - 0.5, 0, -d / 2 - 0.5), 3 * math.pi / 2)
	local zpxnCorner = cornerPart(o * CFrame.new(-w / 2 - 0.5, 0,  d / 2 + 0.5),     0)
	
	return brick, w, h, d
end

g.corners = function(brick)
	local w, h, d = brick.Size.X, brick.Size.Y, brick.Size.Z
	local c = {
		Vector3.new(w / 2, h / 2, d / 2),
		Vector3.new(w / 2, h / 2, -d / 2),
		Vector3.new(w / 2, -h / 2, d / 2),
		Vector3.new(w / 2, -h / 2, -d / 2),
		Vector3.new(-w / 2, h / 2, d / 2),
		Vector3.new(-w / 2, h / 2, -d / 2),
		Vector3.new(-w / 2, -h / 2, d / 2),
		Vector3.new(-w / 2, -h / 2, -d / 2)
	}
	return c
end

g.visualCenter = function(camera, part)
	local corners = g.corners(part)
	local sumX, sumY = 0, 0
	for i,v in next, corners do
		local s = camera:WorldToScreenPoint(v)
		sumX = sumX + s.X
		sumY = sumY + s.Y
	end
	return Vector2.new(sumX / 8, sumY / 8)
end

g.createViewport = function(b, info, updateFunction)
	local i, w, h, d = g.createIcon(b, info)
	local c = Instance.new("Camera")
	local v = Instance.new("ViewportFrame")
	w, d = w + 1, d + 1
	
	i:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
	
	--local angle = CFrame.Angles(0, math.rad(-25), 0) * CFrame.Angles(math.rad(-25), 0, 0)
	local angle = CFrame.Angles(0, math.rad(-45), 0) * CFrame.Angles(math.rad(-30), 0, 0)
	local distance = math.sqrt(w^2+h^2+d^2) * 1.4
	c.CoordinateFrame = angle * CFrame.new(0, 0, distance)
	c.FieldOfView = 50
	
	local original = v.AbsolutePosition
	
	local vc = g.visualCenter(c, i.PrimaryPart)
	vc = Vector2.new(vc.X - original.X, vc.Y - original.Y)
	
	c.CoordinateFrame = c.CoordinateFrame * CFrame.new(vc.X / 4, vc.Y / 4, 0)
	
	v.CurrentCamera = c
	v.BackgroundTransparency = 1
	
	local mouse = false
	local spin = false
	v.MouseEnter:connect(function()
		mouse = true
		delay(0.2, function()
			if mouse then
				spin = true
			end
		end)
	end)
	v.MouseLeave:connect(function()
		mouse = false
		spin = false
	end)
	
	local connection
	local cfCurrent, cfTarget = CFrame.new(), CFrame.new()
	connection = game:GetService("RunService").RenderStepped:connect(function()
		if v.Parent == nil then
			connection:disconnect()
			return
		end
		
		cfTarget = spin and cfTarget * CFrame.Angles(0, math.rad(-1), 0) or CFrame.new()
		cfCurrent = cfCurrent:lerp(cfTarget, 0.05)
		
		i:SetPrimaryPartCFrame(updateFunction and updateFunction() or cfCurrent)
	end)
	
	c.Parent = v
	i.Parent = v
	
	return v
end

return g
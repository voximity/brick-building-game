local g = {}

g.getBrick = function(id)
	for _,cat in next, g.bricks do
		for i,v in next, cat[2] do
			if v.id == id then
				return v
			end
		end
	end
end

g.truncate = function(x, n)
	return tostring(x):sub(1, n + 2)
end

g.brickInfo = function(w, h, d, subtype, asset, standard)
	local info = {}
	
	info.width, info.height, info.depth = w, h, d
	info.standard = standard or true
	info.subtype = subtype or "normal"
	info.asset = asset or nil
	info.id = g.truncate(info.width, 4) .. "x" .. g.truncate(info.height, 4) .. "x" .. g.truncate(info.depth, 4) .. "_" .. info.subtype
	if info.asset then info.id = info.id .. "_" .. info.asset.Name end
	
	info.size = function()
		return Vector3.new(info.width, info.height, info.depth)
	end
	info.sizeTable = function() return {info.width, info.height, info.depth} end
	info.sizeTuple = function() return unpack(info.sizeTable()) end
	
	return info
end

g.fixBrickInfo = function(info)
	return g.brickInfo(info.width, info.height, info.depth, info.subtype, info.asset, info.standard)
end

g.colorBrick = function(brick, color)
	for i,v in next, brick:GetChildren() do
		if v:IsA("BasePart") then
			v.Color = color.color3
			v.Transparency = color.trans
			v.Material = color.material
		end
	end
end

local assets = game:GetService("ReplicatedStorage").Assets
local bi = g.brickInfo
g.bricks = {
	{"1x 1xN Bricks", {
		bi(1, 1, 1),
		bi(2, 1, 1),
		bi(3, 1, 1),
		bi(4, 1, 1),
		bi(8, 1, 1),
		
		bi(1, 1/3, 1),
		bi(2, 1/3, 1),
		bi(4, 1/3, 1),
		bi(8, 1/3, 1)
	}},
	{"1x 2xN", {
		bi(2, 1, 2),
		bi(3, 1, 2),
		bi(4, 1, 2),
		bi(8, 1, 2),
		bi(16, 1, 2),
		
		bi(2, 1/3, 2),
		bi(4, 1/3, 2),
		bi(8, 1/3, 2),
		bi(16, 1/3, 2)
	}},
	{"1x 4xN", {
		bi(4, 1, 4),
		bi(8, 1, 4),
		bi(16, 1, 4),
		
		bi(4, 1/3, 4),
		bi(8, 1/3, 4),
		bi(16, 1/3, 4)
	}},
	{"2x NxN Bricks", {
		bi(1, 2, 1),
		bi(2, 2, 1),
		bi(4, 2, 1),
		bi(8, 2, 1),
		
		bi(2, 2, 2),
		bi(4, 2, 2),
		bi(8, 2, 2),
		bi(16, 2, 2),
		
		bi(4, 2, 4),
		bi(8, 2, 4),
		bi(16, 2, 4),
	}},
	{"5x NxN Bricks", {
		bi(1, 5, 1),
		bi(2, 5, 1),
		bi(4, 5, 1),
		bi(8, 5, 1),
		
		bi(2, 5, 2),
		bi(4, 5, 2),
		bi(8, 5, 2),
		bi(16, 5, 2),
		
		bi(4, 5, 4),
		bi(8, 5, 4),
		bi(16, 5, 4),
	}},
	{"Wedges", {
		bi(1, 1, 2, "wedge"),
		bi(2, 1, 2, "wedge"),
		bi(4, 1, 2, "wedge"),
		bi(1, 3, 4, "wedge"),
		bi(2, 3, 4, "wedge"),
		bi(4, 3, 4, "wedge"),
		
		bi(1, 1, 2, "flipped_wedge"),
		bi(2, 1, 2, "flipped_wedge"),
		bi(4, 1, 2, "flipped_wedge"),
		bi(1, 3, 4, "flipped_wedge"),
		bi(2, 3, 4, "flipped_wedge"),
		bi(4, 3, 4, "flipped_wedge")
	}},
	{"Corner Wedges", {
		bi(2, 1, 2, "outer_wedge"),
		bi(2, 1, 2, "inner_wedge"),
		bi(4, 1, 2, "outer_wedge"),
		bi(4, 1, 2, "inner_wedge"),
		bi(4, 1, 4, "outer_wedge"),
		bi(4, 1, 4, "inner_wedge"),
		
		bi(2, 3, 2, "outer_wedge"),
		bi(2, 3, 2, "inner_wedge"),
		bi(4, 3, 2, "outer_wedge"),
		bi(4, 3, 2, "inner_wedge"),
		bi(4, 3, 4, "outer_wedge"),
		bi(4, 3, 4, "inner_wedge"),
	}},
	{"Rounds", {
		bi(1, 1, 1, "circle"),
		bi(2, 1, 2, "circle"),
		bi(3, 1, 3, "circle"),
		bi(4, 1, 4, "circle"),
		
		bi(1, 2, 1, "circle"),
		bi(2, 2, 2, "circle"),
		bi(4, 2, 4, "circle"),
		
		bi(1, 1/3, 1, "circle"),
		bi(2, 1/3, 2, "circle"),
		bi(3, 1/3, 3, "circle"),
		bi(4, 1/3, 4, "circle")
	}},
	{"Special", {
		bi(4, 2, 1, "custom", assets.Bricks.Fence1),
	}},
	{"Baseplates", {
		bi(5, 1/3, 5, "baseplate"),
		bi(10, 1/3, 10, "baseplate"),
		bi(16, 1/3, 16, "baseplate"),
		bi(32, 1/3, 32, "baseplate"),
		bi(64, 1/3, 64, "baseplate")
	}},
}

g.createStandardBrick = function(info, color)
	assert(info.standard, "Brick info provided is not a standard brick")
	
	local function part()
		local p = Instance.new("Part")
		p.Anchored = true
		p.TopSurface = "Smooth"
		p.BottomSurface = "Smooth"
		p.Material = color.material
		p.Color = color.color3
		p.Transparency = color.trans
		return p
	end
	local function rootMesh(r)
		Instance.new("BlockMesh", r).Scale = Vector3.new()
	end
	
	local function texture(p)
		local topTexture = Instance.new("Texture")
		topTexture.Name = "TopTexture"
		topTexture.Texture = "rbxgameasset://Images/block_tile"
		topTexture.Face = "Top"
		topTexture.StudsPerTileU, topTexture.StudsPerTileV = 1, 1
		
		local bottomTexture = topTexture:Clone()
		bottomTexture.Name = "BottomTexture"
		bottomTexture.Texture = "rbxgameasset://Images/block_tile_inset"
		bottomTexture.Face = "Bottom"
		
		topTexture.Parent = p
		bottomTexture.Parent = p
	end
	
	local model = Instance.new("Model")
	model.Name = "Brick"
	local brickId = Instance.new("StringValue")
	brickId.Name = "BrickId"
	brickId.Value = info.id
	brickId.Parent = model
	
	if info.subtype == "normal" or info.subtype == "baseplate" then
		local brick = part()
		brick.Name = "Brick"
		brick.Size = info.size()
		
		texture(brick)
		
		if info.subtype == "baseplate" then
			local v = Instance.new("BoolValue")
			v.Name = "Baseplate"
			v.Value = true
			v.Parent = model
		end
		
		brick.Parent = model
		model.PrimaryPart = brick
	elseif info.subtype == "wedge" then
		local root = part()
		rootMesh(root)
		root.Size = info.size()
		root.CanCollide = false
		root.Name = "Root"
		
		local base = part()
		base.Size = Vector3.new(info.width, 1/3, info.depth)
		texture(base)
		
		local wedge = Instance.new("WedgePart")
		wedge.Anchored = true
		wedge.Material = color.material
		wedge.Color = color.color3
		wedge.Transparency = color.trans
		wedge.TopSurface = "Smooth"
		wedge.BottomSurface = "Smooth"
		wedge.Size = Vector3.new(info.width, info.height - 1/3, info.depth - 1)
		
		local top = part()
		top.Size = Vector3.new(info.width, info.height - 1/3, 1)
		texture(top)
		
		base.CFrame = root.CFrame * CFrame.new(0, -info.height / 2 + 1/6, 0)
		wedge.CFrame = root.CFrame * CFrame.new(0, 1/6, 1/2) * CFrame.Angles(0, math.pi, 0)
		top.CFrame = root.CFrame * CFrame.new(0, 1/6, -info.depth / 2 + 1/2)
		
		root.Parent = model
		base.Parent = model
		wedge.Parent = model
		top.Parent = model
		model.PrimaryPart = root
	elseif info.subtype == "flipped_wedge" then
		local root = part()
		rootMesh(root)
		root.Size = info.size()
		root.CanCollide = false
		root.Name = "Root"
		
		local base = part()
		base.Size = Vector3.new(info.width, 1/3, info.depth)
		texture(base)
		
		local wedge = Instance.new("WedgePart")
		wedge.Anchored = true
		wedge.Material = color.material
		wedge.Color = color.color3
		wedge.Transparency = color.trans
		wedge.TopSurface = "Smooth"
		wedge.BottomSurface = "Smooth"
		wedge.Size = Vector3.new(info.width, info.height - 1/3, info.depth - 1)
		
		local top = part()
		top.Size = Vector3.new(info.width, info.height - 1/3, 1)
		texture(top)
		
		base.CFrame = root.CFrame * CFrame.new(0, info.height / 2 - 1/6, 0)
		wedge.CFrame = root.CFrame * CFrame.new(0, -1/6, 1/2) * CFrame.Angles(math.pi, 0, 0)
		top.CFrame = root.CFrame * CFrame.new(0, -1/6, -info.depth / 2 + 1/2)
		
		root.Parent = model
		base.Parent = model
		wedge.Parent = model
		top.Parent = model
		model.PrimaryPart = root
	elseif info.subtype == "inner_wedge" then
		local root = part()
		rootMesh(root)
		root.Size = info.size()
		root.CanCollide = false
		root.Name = "Root"
		
		local base = part()
		base.Size = Vector3.new(info.width, 1/3, info.depth)
		texture(base)
		
		local wedgeA = Instance.new("WedgePart")
		wedgeA.Anchored = true
		wedgeA.Material = color.material
		wedgeA.Color = color.color3
		wedgeA.Transparency = color.trans
		wedgeA.TopSurface = "Smooth"
		wedgeA.BottomSurface = "Smooth"
		wedgeA.Size = Vector3.new(info.width - 1, info.height - 1/3, info.depth - 1)
		local wedgeB = wedgeA:Clone()
		wedgeB.Size = Vector3.new(info.depth - 1, info.height - 1/3, info.width - 1)
		
		local topIn = part()
		topIn.Size = Vector3.new(1, info.height - 1/3, 1)
		texture(topIn)
		
		local topW = topIn:Clone()
		topW.Size = Vector3.new(info.width - 1, info.height - 1/3, 1)
		
		local topD = topIn:Clone()
		topD.Size = Vector3.new(1, info.height - 1/3, info.depth - 1)
		
		local w1, d1 = info.width - 1, info.depth - 1
		
		base.CFrame = root.CFrame * CFrame.new(0, -info.height / 2 + 1/6, 0)
		wedgeA.CFrame = root.CFrame * CFrame.new(-info.width / 2 + w1 / 2, 1/6, info.depth / 2 - d1 / 2) * CFrame.Angles(0, math.pi, 0)
		wedgeB.CFrame = wedgeA.CFrame * CFrame.Angles(0, -math.pi / 2, 0)
		topIn.CFrame = root.CFrame * CFrame.new(info.width / 2 - 1/2, 1/6, -info.depth / 2 + 1/2)
		topW.CFrame = root.CFrame * CFrame.new(-info.width / 2 + w1 / 2, 1/6, -info.depth / 2 + 1/2)
		topD.CFrame = root.CFrame * CFrame.new(info.width / 2 - 1/2, 1/6, info.depth / 2 - d1 / 2)
		
		root.Parent = model
		base.Parent = model
		wedgeA.Parent = model
		wedgeB.Parent = model
		topIn.Parent = model
		topW.Parent = model
		topD.Parent = model
		model.PrimaryPart = root
	elseif info.subtype == "outer_wedge" then
		local root = part()
		rootMesh(root)
		root.Size = info.size()
		root.CanCollide = false
		root.Name = "Root"
		
		local base = part()
		base.Size = Vector3.new(info.width, 1/3, info.depth)
		texture(base)
		
		local wedgeA = Instance.new("WedgePart")
		wedgeA.Anchored = true
		wedgeA.Material = color.material
		wedgeA.Color = color.color3
		wedgeA.Transparency = color.trans
		wedgeA.TopSurface = "Smooth"
		wedgeA.BottomSurface = "Smooth"
		wedgeA.Size = Vector3.new(1, info.height - 1/3, info.width - 1)
		local wedgeB = wedgeA:Clone()
		wedgeB.Size = Vector3.new(1, info.height - 1/3, info.depth - 1)
		
		local corner = Instance.new("CornerWedgePart")
		corner.Anchored = true
		corner.Material = color.material
		corner.Color = color.color3
		corner.Transparency = color.trans
		corner.TopSurface = "Smooth"
		corner.BottomSurface = "Smooth"
		corner.Size = Vector3.new(info.width - 1, info.height - 1/3, info.depth - 1)
		
		local top = part()
		top.Size = Vector3.new(1, info.height - 1/3, 1)
		texture(top)
		
		local w1, d1 = info.width - 1, info.depth - 1
		
		base.CFrame = root.CFrame * CFrame.new(0, -info.height / 2 + 1/6, 0)
		top.CFrame = root.CFrame * CFrame.new(info.width / 2 - 1/2, 1/6, -info.depth / 2 + 1/2)
		wedgeA.CFrame = root.CFrame * CFrame.new(-info.width / 2 + w1 / 2, 1/6, -info.depth / 2 + 1/2) * CFrame.Angles(0, math.pi / 2, 0)
		wedgeB.CFrame = root.CFrame * CFrame.new(info.width / 2 - 1/2, 1/6, info.depth / 2 - d1 / 2) * CFrame.Angles(0, math.pi, 0)
		corner.CFrame = root.CFrame * CFrame.new(-info.width / 2 + w1 / 2, 1/6, info.depth / 2 - d1 / 2)
		
		root.Parent = model
		base.Parent = model
		wedgeA.Parent = model
		wedgeB.Parent = model
		corner.Parent = model
		top.Parent = model
		model.PrimaryPart = root
	elseif info.subtype == "circle" then
		local root = part()
		rootMesh(root)
		root.Size = info.size()
		root.CanCollide = false
		root.Name = "Root"
		
		if info.height < 1 then
			local bs = info.size()
			local ts = info.size() * Vector3.new(1, 0, 1) + Vector3.new(0, 1/9, 0)
			
			local base = part()
			base.Shape = Enum.PartType.Cylinder
			base.Size = Vector3.new(info.height - ts.Y, bs.X * 0.8, bs.Z * 0.8)
			base.CFrame = root.CFrame * CFrame.new(0, -ts.Y / 2, 0) * CFrame.Angles(0, 0, math.pi / 2)
			texture(base)
			base.TopTexture.Face = "Right"
			base.BottomTexture.Face = "Left"
			
			local top = part()
			top.Shape = Enum.PartType.Cylinder
			top.Size = Vector3.new(ts.Y, ts.X, ts.Z)
			top.CFrame = root.CFrame * CFrame.new(0, info.height / 2 - 1/18, 0) * CFrame.Angles(0, 0, math.pi / 2)
			texture(top)
			top.TopTexture.Face = "Right"
			top.BottomTexture.Face = "Left"
		
			root.Parent = model
			base.Parent = model
			top.Parent = model
			model.PrimaryPart = root
		else
			local base = part()
			base.Shape = Enum.PartType.Cylinder
			base.Size = Vector3.new(info.height, info.width, info.depth)
			base.CFrame = root.CFrame * CFrame.Angles(0, 0, math.pi / 2)
			texture(base)
			base.TopTexture.Face = "Right"
			base.BottomTexture.Face = "Left"
			
			root.Parent = model
			base.Parent = model
			model.PrimaryPart = root
		end
	elseif info.subtype == "custom" then
		local a = info.asset:Clone()
		local pp = a.PrimaryPart
		for i,v in next, a:GetChildren() do
			v.Anchored = true
			v.TopSurface = "Smooth"
			v.BottomSurface = "Smooth"
			v.Material = color.material
			if v.Transparency == 1 then v.Transparency = color.trans rootMesh(v) else v.Transparency = color.trans end
			v.Color = color.color3
			v.Parent = model
		end
		
		if pp then model.PrimaryPart = pp else model.PrimaryPart = a:GetChildren()[1] end
	end
	
	return model, info
end

return g
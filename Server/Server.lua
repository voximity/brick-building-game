local load = require(game:GetService("ReplicatedStorage").Shared.Load)(script)
---------------------------------------------------------------------------------

local bg = load("/Shared/BrickGenerator")
local ms = load("/Shared/MenuSound")
local network = load("/Shared/Network")
local ep = load("./EventParser")
local chat = load("./Chat")
local usd = load("/Shared/UserdataDeserializer")
local lzw = load("/Shared/LzwCompression")

local players = game:GetService("Players")
local ds = game:GetService("DataStoreService")

function checkForIntersection(position, size, player)
	local off = Vector3.new(0.1, 0.1, 0.1)
	local parts = workspace:FindPartsInRegion3WithIgnoreList(Region3.new(position - (size - off) / 2, position + (size - off) / 2), {player.Character})
	return #parts > 0
end
function lookVectorToRotation(lv)
	if lv == Vector3.new(0, 0, -1) then return 0
	elseif lv == Vector3.new(0, 0, 1) then return 2
	elseif lv == Vector3.new(-1, 0, 0) then return 3
	else return 1
	end
end
function getPartSize(cf, info)
	local size = info.size()
	return lookVectorToRotation(cf.lookVector) % 2 == 1 and Vector3.new(size.Z, size.Y, size.X) or size	
end

network.on("brick place", function(player, cframes, info, color, supporting, vertical)
	local last
	if vertical then last = supporting[1][2] end
	
	for i,v in next, cframes do
		if not checkForIntersection(v.p, getPartSize(v, bg.fixBrickInfo(info)), player) then
			local brick = bg.createStandardBrick(bg.fixBrickInfo(info), color)
			brick:SetPrimaryPartCFrame(v)
			brick.Name = "Brick"
			
			local owner = Instance.new("ObjectValue")
			owner.Name = "Owner"
			owner.Value = player
			owner.Parent = brick
			
			if not vertical then last = supporting[i][2] end
			
			local sval = Instance.new("ObjectValue")
			sval.Name = "Supported"
			sval.Value = last or workspace.Base
			sval.Parent = brick
			
			if last ~= workspace.Base then
				local spval = Instance.new("ObjectValue")
				spval.Name = "Supporting"
				spval.Value = brick
				spval.Parent = last
			end
			
			if vertical then
				last = brick
			end
			
			brick.Parent = workspace
			if i == 1 then
				ms.play(ms.click(), brick.PrimaryPart)
			end
		end
	end
end)

network.on("camera angle", function(player, cframe)
	network.sendToAll("camera angle", player, cframe)
end)

network.on("equip", function(player, reference)
	network.sendToAll("equip", player, reference)
end)
network.on("unequip", function(player, reference)
	network.sendToAll("unequip", player)
end)

network.on("brick color", function(player, brick, color)
	network.sendToAll("brick color", brick, color)
	wait(1)
	bg.colorBrick(brick, color)
end)

network.on("set supporting", function(player, a, b)
	local spval = Instance.new("ObjectValue")
	spval.Name = "Supporting"
	spval.Value = b
	spval.Parent = a
end)

network.on("set supported", function(player, a, b)
	a.Supported.Value = b
end)

local saves = ds:GetDataStore("Saves")
network.onFunction("get saves", function(player)
	local data = saves:GetAsync(player.UserId .. "_SaveData") or {
		saves = {}
	}
	if not data then
		saves:SetAsync(player.UserId .. "_SaveData", data)
	end
	
	local saveDatas = {}
	for i,v in next, data.saves do
		local data
		pcall(function()
			data = game:GetService("HttpService"):JSONDecode(lzw.decompress(saves:GetAsync(player.UserId .. "_Save_" .. v)))
		end)
		if data then
			table.insert(saveDatas, {name = data.name, size = data.size, baseplates = data.baseplates, total = data.total, modified = data.modified})
		end
	end
	
	return saveDatas
end)

network.onFunction("save", function(player, baseplates, allBricks, totalSize, saveData, saveName)
	local save = {
		name = saveName,
		size = "(" .. math.floor(totalSize.X + 0.5) .. "," .. (tostring(totalSize.Y):sub(1, 8)) .. "," .. math.floor(totalSize.Z + 0.5) .. ")",
		baseplates = baseplates,
		total = allBricks,
		saveData = saveData,
		modified = os.time()--string.gsub("{month}/{day}/{year} {hour}:{min}", "{(%w+)}", os.date("!*t", os.time()))
	}
	
	local data = saves:GetAsync(player.UserId .. "_SaveData") or {
		saves = {}
	}
	
	local isIn = false
	for i,v in next, data.saves do
		if v == saveName then
			isIn = true
			break
		end
	end
	
	if not isIn then table.insert(data.saves, saveName) end
	
	saves:SetAsync(player.UserId .. "_SaveData", data)
	local saveString = game:GetService("HttpService"):JSONEncode(save)
	local compressed = lzw.compress(saveString)
	saves:SetAsync(player.UserId .. "_Save_" .. saveName, compressed)
	chat.add("Successfully saved. <Bright blue>" .. math.floor(#compressed / #saveString * 100) .. "%<> of original size after compression.", player)
	
	return true
end)

network.onFunction("remove save", function(player, saveName)
	local data = saves:GetAsync(player.UserId .. "_SaveData") or {
		saves = {}
	}
	for i = #data.saves, 1, -1 do
		if data.saves[i] == saveName then
			table.remove(data.saves, i)
		end
	end
	local x = saves:RemoveAsync(player.UserId .. "_Save_" .. saveName)
	saves:SetAsync(player.UserId .. "_SaveData", data)
	
	return x ~= nil
end)

network.onFunction("place save", function(player, saveName, position, rotation)
	local startTime = tick()
	
	local saveCompressed = saves:GetAsync(player.UserId .. "_Save_" .. saveName)
	local save = game:GetService("HttpService"):JSONDecode(lzw.decompress(saveCompressed))
	
	local loaded = {}
	for i,v in next, save.saveData do
		local color = {
			brickColor = usd.brickcolor(v.color.brickColor),
			color3 = usd.color3(v.color.color3),
			material = Enum.Material[v.color.material],
			trans = v.color.trans
		}
		
		local brick = bg.createStandardBrick(bg.getBrick(v.id), color)
		brick:SetPrimaryPartCFrame(CFrame.new(position) * CFrame.Angles(0, math.pi / 2 * -(rotation or 0), 0) * CFrame.new(usd.vector3(v.position)) * CFrame.Angles(0, math.pi / 2 * v.rotation, 0))
		table.insert(loaded, brick)
	end
	
	for i,v in next, save.saveData do
		local owner = Instance.new("ObjectValue")
		owner.Name = "Owner"
		owner.Value = player
		owner.Parent = loaded[i]
		
		local supported = Instance.new("ObjectValue")
		supported.Name = "Supported"
		supported.Value = v.supported == "base" and workspace.Base or loaded[v.supported]
		supported.Parent = loaded[i]
		
		for a,b in next, v.supporting or {} do
			local supporting = Instance.new("ObjectValue")
			supporting.Name = "Supporting"
			supporting.Value = loaded[b]
			supporting.Parent = loaded[i]
		end
	end
	
	for i,v in next, loaded do
		v.Parent = workspace
	end
	
	chat.add("Successfully loaded <Bright blue>" .. chat.formatNumber(#loaded) .. " bricks<> in <Bright blue>" .. (math.floor((tick() - startTime) * 1000) / 1000) .. "s<>.", player)
	
	return true
end)

network.on("brick remove", function(player, brick)
	if brick:FindFirstChild("Owner") and brick.Owner.Value == player then
		if brick:FindFirstChild("Supported") then
			local s = brick.Supported.Value
			for i,v in next, s:GetChildren() do
				if v.Name == "Supporting" and v.Value == brick then
					v:Destroy()
				end
			end
		end
		ms.play(ms.hit(), brick.PrimaryPart)
		network.sendToAll("brick remove", brick:GetPrimaryPartCFrame(), bg.getBrick(brick.BrickId.Value), {trans = 0, color3 = brick.PrimaryPart.Color, material = brick.PrimaryPart.Material})
		brick:Destroy()
	end
end)

players.PlayerRemoving:connect(function(player)
	for i,v in next, workspace:GetChildren() do
		if v.Name == "Brick" and v:FindFirstChild("Owner") and v.Owner.Value == player then
			local supported = v:FindFirstChild("Supported")
			if supported then
				for a,b in next, supported:GetChildren() do
					if b.Name == "Supporting" and b.Value == v then
						b:Destroy()
					end
				end
			end
			
			v:Destroy()
		end
	end
end)

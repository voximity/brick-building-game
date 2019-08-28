local load = require(game:GetService("ReplicatedStorage").Shared.Load)(script)
---------------------------------------------------------------------------------
local bg, big = load("/Shared/BrickGenerator"), load("../../BrickIconGenerator")
local ms = load("/Shared/MenuSound")
local kb = load("../../Keyboard")
local colors = load("/Shared/Colors")
local network = load("/Shared/Network")
local bricks = bg.bricks

local input = game:GetService("UserInputService")
local assets = game:GetService("ReplicatedStorage").Assets

local tool = {}

tool.notification = nil
tool.tools = {}

tool.hotbar = {
	{4, 1, 2}
}
tool.ui = nil
tool.invUi = nil

tool.selected = 1
tool.slots = 10
tool.slotSize = 80
tool.color = colors.color(BrickColor.new("Bright red"))

tool.active = false

--[[for i = 1, tool.slots do
	tool.hotbar[i] = {3 + i, 1, 2}
end]]

for i = 1, tool.slots do
	if tool.hotbar[i] == nil then
		tool.hotbar[i] = -1
	else
		local v = tool.hotbar[i]
		tool.hotbar[i] = bg.brickInfo(v[1], v[2], v[3])
	end
end

tool.createHotbar = function(p)
	local h = Instance.new("Frame")
	tool.ui = h
	h.BorderSizePixel = 0
	h.Size = UDim2.new(0, tool.slots * tool.slotSize, 0, tool.slotSize)
	h.Position = UDim2.new(0.5, -h.Size.X.Offset / 2, 1, 0)
	h.BackgroundColor3 = Color3.new(1, 1, 1)
	
	local inv = Instance.new("Frame")
	tool.invUi = inv
	inv.BorderSizePixel = 0
	inv.Size = UDim2.new(1, 0, 0, 500)
	inv.Position = UDim2.new(0, 0, 1, 0)
	inv.BackgroundColor3 = Color3.new(1, 1, 1)
	
	tool.createInventory(inv)
	inv.Parent = h
	
	local s = Instance.new("Frame")
	s.BorderSizePixel = 0
	s.Size = UDim2.new(0, tool.slotSize, 0, tool.slotSize)
	s.Name = "Selector"
	s.Parent = h
	
	local f = Instance.new("Folder")
	f.Name = "Viewports"
	f.Parent = h
	
	h.Parent = p
	
	tool.updateHotbar()
	
	return h
end

local inventorySlots = 8
local invSlotSize = tool.slots * tool.slotSize / inventorySlots

tool.createInventory = function(inv)
	inv:ClearAllChildren()
	
	local scroller = Instance.new("ScrollingFrame")
	scroller.Size = UDim2.new(1, 0, 1, 0)
	scroller.ScrollBarThickness = 0
	scroller.BackgroundTransparency = 1
	
	local catSizes = 0
	for categoryIndex, category in next, bricks do
		local cat = Instance.new("Frame")
		cat.Size = UDim2.new(1, 0, 0, math.ceil(#category[2] / inventorySlots) * invSlotSize + 24)
		cat.Position = UDim2.new(0, 0, 0, catSizes)
		cat.BorderSizePixel = 0
		cat.BackgroundColor3 = Color3.new(0, 0, 0):lerp(tool.color.color3, categoryIndex % 2 == 0 and 0.8 or 0.65)
		cat.Parent = scroller
		
		local label = Instance.new("TextLabel")
		label.Text = category[1]
		label.Font = "SourceSansBold"
		label.TextSize = 20
		label.TextXAlignment = "Left"
		label.Size = UDim2.new(1, -20, 0, 24)
		label.Position = UDim2.new(0, 10, 0, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0
		label.TextStrokeColor3 = Color3.new(0, 0, 0)
		label.Parent = cat
		
		for brickIndex, brick in next, category[2] do
			local viewport = big.createViewport(bg.createStandardBrick(brick, tool.color))
			viewport.Size = UDim2.new(0, invSlotSize, 0, invSlotSize)
			viewport.BackgroundTransparency = 1
			viewport.Position = UDim2.new(0, ((brickIndex - 1) % inventorySlots) * invSlotSize, 0, math.floor((brickIndex - 1) / inventorySlots) * invSlotSize + 24)
			viewport.Parent = cat
			
			local w, h, d = brick.width, brick.height, brick.depth
			local ws, hs, ds = tostring(w), h * 3 == math.floor(h * 3) and h ~= math.floor(h) and tostring(h * 3) .. "/3" or tostring(h), tostring(d)
			
			local sizeLabel = label:Clone()
			sizeLabel.Text = hs .. "x   " .. ws .. "x" .. ds
			sizeLabel.TextXAlignment = "Center"
			sizeLabel.TextYAlignment = "Bottom"
			sizeLabel.TextSize = 14
			sizeLabel.Size = UDim2.new(1, -10, 1, -10)
			sizeLabel.Position = UDim2.new(0, 5, 0, 5)
			sizeLabel.Font = "SourceSans"
			sizeLabel.Parent = viewport
			
			viewport.MouseEnter:connect(function()
				ms.play(ms.hover())
			end)
			
			viewport.InputEnded:connect(function(io)
				if io.UserInputType == Enum.UserInputType.MouseButton1 then
					tool.hotbar[tool.selected] = brick
					tool.selected = (tool.selected) % 10 + 1
					tool.updateHotbar()
					ms.play(ms.click())
				end
			end)
		end
		
		catSizes = catSizes + cat.Size.Y.Offset
	end
	scroller.CanvasSize = UDim2.new(1, 0, 0, catSizes)
	scroller.Parent = inv
end

tool.lastInfo = nil

tool.updateHotbar = function(opened)
	tool.ui.Selector.BackgroundColor3 = Color3.new():lerp(tool.color.color3, 0.7)
	
	local selectorPos = UDim2.new(0, tool.slotSize * (tool.selected - 1), 0, 0)
	if not opened then
		tool.ui.Selector:TweenPosition(selectorPos, "InOut", "Quint", 0.2, true)
	else
		tool.ui.Selector.Position = selectorPos
	end
	
	if tool.vm.current.model then
		local model = tool.vm.current.model
		tool.surfaceUi:ClearAllChildren()
		
		if tool.hotbar[tool.selected] ~= -1 then
			local brick, info = bg.createStandardBrick(tool.hotbar[tool.selected], tool.color)
			
			local rot = CFrame.new()
			local icon = big.createViewport(brick, info, function()
				local c = workspace.CurrentCamera
				
				rot = rot:lerp(CFrame.Angles(0, tool.placingRotation * -math.pi / 2, 0), 0.5)
				return 
					rot 
					* CFrame.new(Vector3.new(), c.CFrame.lookVector * Vector3.new(1, 0, 1)):inverse()
					* CFrame.Angles(0, -math.pi / 4, 0)
			end)
			
			icon.Size = UDim2.new(1, 0, 1, 0)
			icon.Parent = tool.surfaceUi
		end
	end
	
	ms.play(ms.hover())
	
	local now = tool.hotbar[tool.selected]
	if tool.placing then
		if now ~= -1 and tool.lastInfo and tool.lastInfo.standard and now.standard and now.subtype == "normal" and tool.lastInfo.subtype == "normal" then
			game:GetService("TweenService"):Create(tool.placing.PrimaryPart, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Size = now.size()}):Play()
		else
			tool.placing:Destroy()
			tool.placing = nil
		end
	end
	
	tool.lastInfo = tool.hotbar[tool.selected]
	
	for i,v in next, tool.hotbar do
		local old = tool.ui.Viewports:FindFirstChild(tostring(i))
		
		if not old or (old and old:IsA("Frame") and not old:IsA("ViewportFrame")) or (old and old:IsA("ViewportFrame") and (old.Brick.PrimaryPart.Color ~= tool.color.color3 or old.Brick.PrimaryPart.Size ~= v.size())) then
			local icon
			if v ~= -1 and v.width and v.height and v.depth then
				icon = big.createViewport(bg.createStandardBrick(v, tool.color))
				icon.Size = UDim2.new(0, tool.slotSize, 0, tool.slotSize)
				icon.Position = UDim2.new(0, tool.slotSize * (i - 1), 0, 0)
				icon.Name = tostring(i)
				icon.Parent = tool.ui.Viewports
			else
				icon = Instance.new("Frame")
				icon.BackgroundTransparency = 1
				icon.Size = UDim2.new(0, tool.slotSize, 0, tool.slotSize)
				icon.Position = UDim2.new(0, tool.slotSize * (i - 1), 0, 0)
				icon.Name = tostring(i)
				icon.Parent = tool.ui.Viewports
			end
			
			icon.InputBegan:connect(function(io)
				if io.UserInputType == Enum.UserInputType.MouseButton1 then
					tool.selected = i
					tool.updateHotbar()
				end
			end)
			
			local label = Instance.new("TextLabel")
			label.Text = tostring(i % 10)
			label.TextXAlignment = "Left"
			label.TextYAlignment = "Top"
			label.Font = "SourceSansBold"
			label.TextSize = 20
			label.TextColor3 = Color3.new(1, 1, 1)
			label.TextStrokeTransparency = 0
			label.TextStrokeColor3 = Color3.new(0, 0, 0)
			label.Size = UDim2.new(1, -8, 1, -8)
			label.Position = UDim2.new(0, 8, 0, 4)
			label.BackgroundTransparency = 1
			label.Parent = icon
			
			if old then old:Destroy() end
		end
	end
end

tool.invActive = false

tool.surfaceUi = nil

tool.createViewmodel = function()
	tool.vm.create(assets.Tools.BuildTool)
	tool.surfaceUi = tool.vm.current.model.Previewer.SurfaceGui
	tool.surfaceUi.Parent = game.Players.LocalPlayer.PlayerGui
end

tool.openInventory = function()
	if tool.tools.freecam.active then return end
	if not tool.active then
		tool.active = true
		tool.tools.paint.close()
		tool.tools.remove.close()
		tool.tools.save.close()
		tool.tools.wrench.close()
		tool.updateHotbar(true)
		tool.createViewmodel()
	end
	tool.invActive = true
	input.MouseBehavior = Enum.MouseBehavior.Default
	tool.ui:TweenPosition(UDim2.new(0.5, -tool.ui.Size.X.Offset / 2, 1, -tool.ui.Size.Y.Offset - tool.invUi.Size.Y.Offset), "Out", "Quint", 0.3, true)
end

tool.closeInventory = function()
	tool.invActive = false
	input.MouseBehavior = Enum.MouseBehavior.LockCenter
	tool.ui:TweenPosition(UDim2.new(0.5, -tool.ui.Size.X.Offset / 2, 1, -tool.ui.Size.Y.Offset), "Out", "Quint", 0.3, true)
end

tool.open = function()
	if tool.tools.freecam.active then return end
	tool.tools.paint.close()
	tool.tools.remove.close()
	tool.tools.save.close()
	tool.tools.wrench.close()
	tool.ui:TweenPosition(UDim2.new(0.5, -tool.ui.Size.X.Offset / 2, 1, -tool.ui.Size.Y.Offset), "Out", "Quint", 0.2, true)
	tool.updateHotbar(true)
	tool.createViewmodel()
	tool.active = true
end

tool.close = function()
	if tool.active then
		tool.vm.stop()
	end
	if tool.surfaceUi then tool.surfaceUi:Destroy() end
	tool.surfaceUi = nil
	tool.ui:TweenPosition(UDim2.new(0.5, -tool.ui.Size.X.Offset / 2, 1, 0), "InOut", "Quint", tool.invActive and 0.4 or 0.2, true)
	input.MouseBehavior = Enum.MouseBehavior.LockCenter
	tool.active = false
	tool.invActive = false
end

kb.bind("b", function()
	if tool.invActive then
		tool.closeInventory()
	else
		tool.openInventory()
	end
end)

for i,v in next, {"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "zero"} do
	kb.bind(v, function()
		if tool.dragging then return end
		local opened = false
		if tool.active and tool.selected == i then
			tool.close()
			return
		elseif not tool.active then
			tool.open()
			opened = true
		end
		
		tool.selected = i
		tool.updateHotbar(opened)
	end)
end

tool.placing = nil
tool.placingRotation = 0
tool.placingTouching = nil

tool.placingOrigin = Vector3.new()
tool.placingCursorOrigin = Vector3.new()

tool.placingCFrame = nil

kb.bind("r", function()
	if tool.active and tool.placing then
		tool.placingRotation = tool.placingRotation + 1
		
		tool.vm.playAnimation({
			{duration = 0.04, pos = CFrame.new(), angle = CFrame.Angles(0, 0, math.rad(25))},
			{duration = 0.04, pos = CFrame.new(), angle = CFrame.new()}
		})
	end
end)

local lastnormal = Vector3.new()

tool.nudge = {x = 0, z = 0}
tool.setNudge = function(up, right)
	if not tool.active or not tool.placing then return end
	if (lastnormal * Vector3.new(1, 0, 1)).magnitude > 0 then return end
	
	local c = workspace.CurrentCamera
	local v = c.CFrame.lookVector
	local axisX = math.abs(v.X) > math.abs(v.Z)
	local factor = axisX and (v.X > 0 and 1 or -1) or (v.Z > 0 and 1 or -1)
	local s = tool.hotbar[tool.selected].sizeTable()
	local size = tool.placingRotation % 2 == 1 and Vector3.new(s[3], s[2], s[1]) or Vector3.new(s[1], s[2], s[3])
	
	tool.nudge.x = math.max(math.min(tool.nudge.x + (axisX and factor * up or factor * -right), math.floor((size.X - 0.5) / 2)), -math.floor((size.X - 0.5) / 2))
	tool.nudge.z = math.max(math.min(tool.nudge.z + (axisX and factor * right or factor * up), math.floor((size.Z - 0.5) / 2)), -math.floor((size.Z - 0.5) / 2))
	
	ms.play(ms.hover())
end
tool.nudgeAnim = function(up, right)
	tool.vm.playAnimation({
		{duration = 0.04, pos = CFrame.new(right, up, 0), angle = CFrame.Angles(math.rad(up * 1 / 0.3 * -10), 0, math.rad(right * 1 / 0.3 * -10))},
		{duration = 0.04, pos = CFrame.new(right, up, 0), angle = CFrame.new(0, 0, 0)}
	})
end

kb.bind("i", function()
	tool.nudgeAnim(0.3, 0)
	tool.setNudge(1, 0)
end)
kb.bind("k", function()
	tool.nudgeAnim(-0.3, 0)
	tool.setNudge(-1, 0)
end)
kb.bind("j", function()
	tool.nudgeAnim(0, 0.3)
	tool.setNudge(0, -1)
end)
kb.bind("l", function()
	tool.nudgeAnim(0, -0.3)
	tool.setNudge(0, 1)
end)

function checkForIntersection(position, size)
	local off = Vector3.new(0.1, 0.1, 0.1)
	local parts = workspace:FindPartsInRegion3WithIgnoreList(Region3.new(position - (size - off) / 2, position + (size - off) / 2), {game.Players.LocalPlayer.Character, workspace.CurrentCamera, unpack(tool.tools.remove.sparkList or {})})
	return #parts > 0
end

local p
function debpart(v31, v32)
	if p then p:Destroy() p = nil end
	p = Instance.new("Part")
	p.Anchored = true
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.CanCollide = false
	p.CFrame = CFrame.new(v31:Lerp(v32, 0.5), v32)
	p.Size = Vector3.new(0.2, 0.2, (v31-v32).magnitude)
	p.Parent = workspace
end

function closestDistOfApproach(linePoint1, lineVec1, linePoint2, lineVec2)
	local p1 = Vector3.new()
	local p2 = Vector3.new()
	
	local a = lineVec1:Dot(lineVec1)
	local b = lineVec1:Dot(lineVec2)
	local e = lineVec2:Dot(lineVec2)
	local d = a * e - b * b
	
	local r = linePoint1 - linePoint2
	local c = lineVec1:Dot(r)
	local f = lineVec2:Dot(r)
	local s = (b * f - c * e) / d
	local t = (a * f - c * b) / d
	
	p1 = linePoint1 + lineVec1 * s
	p2 = linePoint2 + lineVec2 * t
	
	return (p1 - p2).magnitude, p1, p2
end

local testy

function getDraggedNormal(cam)
	local cr = Ray.new(cam.CFrame.p, cam.CFrame.lookVector)
	
	local v3 = Vector3.new
	local normals = {
		{v3(1, 0, 0), 0},
		{v3(0, 1, 0), 0},
		{v3(0, 0, 1), 0},
		{v3(-1, 0, 0), 0},
		--{v3(0, -1, 0), 0},
		{v3(0, 0, -1), 0}
	}
	
	for i,v in next, normals do
		v[2] = closestDistOfApproach(cam.CFrame.p, cam.CFrame.lookVector, tool.placingCursorOrigin, v[1])
	end
	
	table.sort(normals, function(a, b)
		if a[2] == b[2] then
			local ad = cr:ClosestPoint(tool.placingCursorOrigin + a[1] * 5)
			local bd = cr:ClosestPoint(tool.placingCursorOrigin + b[1] * 5)
			return (ad - tool.placingCursorOrigin + a[1] * 5).magnitude < (bd - tool.placingCursorOrigin + b[1] * 5).magnitude
		else
			return math.floor(a[2] * 10) / 10 < math.floor(b[2] * 10) / 10
		end
	end)
	
	return normals[1][1]
end

tool.dragging = false

tool.draggedMouseMoved = false
input.InputBegan:connect(function(io)
	if tool.active and tool.placing and not tool.invActive and io.UserInputType == Enum.UserInputType.MouseButton1 then
		tool.placingOrigin = tool.placingCFrame.p
		tool.placingCursorOrigin = tool.placingOrigin - Vector3.new(tool.nudge.x, 0, tool.nudge.z)
		tool.dragging = true
		tool.draggedMouseMoved = false
	end
end)
input.InputChanged:connect(function(io)
	if tool.active and tool.placing and tool.dragging and io.UserInputType == Enum.UserInputType.MouseMovement then
		
		tool.draggedMouseMoved = true
		
	elseif tool.active and not tool.dragging and not tool.invActive and io.UserInputType == Enum.UserInputType.MouseWheel then
		
		local z = io.Position.Z
		tool.selected = tool.selected - z
		if tool.selected > #tool.hotbar then
			tool.selected = 1
		elseif tool.selected < 1 then
			tool.selected = #tool.hotbar
		end
		tool.updateHotbar()
		
	end
end)

function absv3(v3)
	local a = math.abs
	return Vector3.new(a(v3.X), a(v3.Y), a(v3.Z))
end

function getBrickSupporting(brick)
	local b = {}
	for i,v in next, b:GetChildren() do
		if v.Name == "Supports" then
			table.insert(b, v.Value)
		end
	end
	return b
end

function getIntersectingVertical(rawSize, pos, factor, ignore)
	local off = Vector3.new(0.1, 0, 0.1)
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
	
	return parts[1]
end

tool.placeBrick = function()
	tool.vm.playAnimation({
		{duration = 0.04, pos = CFrame.new(0, -0.3, 0.4), angle = CFrame.Angles(math.rad(10), 0, 0)},
		{duration = 0.1, pos = CFrame.new(), angle = CFrame.new()}
	})
	
	tool.dragging = false
	local s = tool.hotbar[tool.selected].sizeTable()
	local rawSize = (tool.placingRotation % 2 == 0 and Vector3.new(s[1], s[2], s[3]) or Vector3.new(s[3], s[2], s[1]))
	local intersects = checkForIntersection(tool.placingCFrame.p - rawSize * (tool.lastDraggedNormal == Vector3.new(0, 1, 0) and -tool.lastDraggedNormal or tool.lastDraggedNormal) * #tool.draggedParts / 2, rawSize + rawSize * absv3(tool.lastDraggedNormal) * #tool.draggedParts)
	
	if not intersects then
		local cfs = {tool.placingCFrame}
		
		for i,v in next, tool.draggedParts do
			table.insert(cfs, v:GetPrimaryPartCFrame())
			v:Destroy()
		end
		local vertical = absv3(tool.lastDraggedNormal).Y > 0
		
		local floating = {}
		local supporting = {}
		
		if vertical then
			local st = getIntersectingVertical(rawSize, cfs[1].p, 1, {game.Players.LocalPlayer.Character, workspace.CurrentCamera, unpack(tool.tools.remove.sparkList or {})})
			local sb = getIntersectingVertical(rawSize, cfs[1].p, -1, {game.Players.LocalPlayer.Character, workspace.CurrentCamera, unpack(tool.tools.remove.sparkList or {})})
			
			st = st and st.Parent.Name == "Brick" and st.Parent or st
			sb = sb and sb.Parent.name == "Brick" and sb.Parent or sb
			
			if not st and not sb then
				table.insert(floating, cfs[1].p)
			else
				table.insert(supporting, {cfs[1].p, sb or st, st, sb})
			end
		else
			for i,v in next, cfs do
				local st = getIntersectingVertical(rawSize, v.p, 1, {game.Players.LocalPlayer.Character, workspace.CurrentCamera, unpack(tool.tools.remove.sparkList or {})})
				local sb = getIntersectingVertical(rawSize, v.p, -1, {game.Players.LocalPlayer.Character, workspace.CurrentCamera, unpack(tool.tools.remove.sparkList or {})})
				if not st and not sb then
					table.insert(floating, v)
					break
				end
				
				st = st and st.Parent.Name == "Brick" and st.Parent or st
				sb = sb and sb.Parent.name == "Brick" and sb.Parent or sb
				
				table.insert(supporting, {v, sb or st, st, sb})
			end
		end
			
		--end
		
		local canPlace = #floating == 0
		local t
		for i,v in next, supporting do
			if v[2] and v[2].Name == "Brick" and v[2]:FindFirstChild("Owner") and v[2].Owner.Value ~= game.Players.LocalPlayer then
				t = v[2]
				canPlace = false
				break
			end
		end
		
		if #floating > 0 then
			tool.notification.show("This brick cannot be floating.", true)
		else
			if canPlace then
				network.send("brick place", cfs, tool.hotbar[tool.selected], tool.color, supporting, absv3(tool.lastDraggedNormal).Y > 0)
			else
				tool.notification.show("This brick cannot be placed on one of " .. (t.Owner.Value.Name) .. "'s bricks.", true)
			end
		end
		
		tool.draggedParts = {}
		tool.lastDraggedNormal = Vector3.new()
	else
		tool.notification.show("An intersection occured while trying to place this brick.", true)
	
		for i,v in next, tool.draggedParts do
			v:Destroy()
		end
		
		tool.draggedParts = {}
		tool.lastDraggedNormal = {}
	end
end

input.InputEnded:connect(function(io)
	if tool.active and tool.placing and not tool.invActive and io.UserInputType == Enum.UserInputType.MouseButton1 then
		tool.placeBrick()
	end
end)

kb.bind("return", function()
	if tool.active and tool.placing and not tool.invActive then
		tool.placeBrick()
	end
end)

tool.draggedParts = {}
tool.lastDraggedNormal = Vector3.new()
tool.draggedAxisSpace = 0

local blinkTimer = 0

game:GetService("RunService").RenderStepped:connect(function(delta)
	if tool.active then
		if tool.hotbar[tool.selected] == -1 then
			if tool.placing then
				tool.placing:Destroy()
				tool.placing = nil
			end
			return
		end
		
		local s = tool.hotbar[tool.selected].sizeTable()
		local c = workspace.CurrentCamera
		
		local size = tool.placingRotation % 2 == 1 and Vector3.new(s[3], s[2], s[1]) or Vector3.new(s[1], s[2], s[3])
		
		tool.placingRotation = tool.placingRotation % 4
		
		local chars = {}
		for i,v in next, workspace:GetChildren() do
			if game.Players:GetPlayerFromCharacter(v) then
				table.insert(chars, v)
			end
		end
		
		local ray = Ray.new(c.CFrame.p, c.CFrame.lookVector * 64)
		local part, hit, normal = workspace:FindPartOnRayWithIgnoreList(ray, {game.Players.LocalPlayer.Character, c, unpack(chars), unpack(tool.tools.remove.sparkList or {})})
		
		if normal ~= lastnormal then
			tool.nudge = {x = 0, z = 0}
		end
		lastnormal = normal
		
		if not tool.dragging then
			tool.placingTouching = part
		end
		
		if tool.dragging then
			local normal = getDraggedNormal(c)
			local _, point1, point2 = closestDistOfApproach(c.CFrame.p, c.CFrame.lookVector, tool.placingCursorOrigin, normal)
			local distance = (point2 - tool.placingCursorOrigin).magnitude
			local axisSpace = (size * normal).magnitude
			local parts = tool.draggedMouseMoved and math.min(math.floor(distance / axisSpace), 14) or 0
			
			for i = 1, parts do
				if tool.draggedParts[i] == nil then
					local dragged = bg.createStandardBrick(tool.hotbar[tool.selected], tool.color)
					dragged:SetPrimaryPartCFrame(CFrame.new(tool.placingOrigin) * CFrame.new((normal == Vector3.new(0, 1, 0) and normal or -normal) * axisSpace * i) * CFrame.Angles(0, math.pi / 2 * -tool.placingRotation, 0))
					for i,v in next, dragged:GetChildren() do
						if v:IsA("BasePart") then
							v.CanCollide = false
							if v.Name ~= "Root" then
								v.Transparency = v.Transparency + 0.3
							end
						end
					end
					dragged.Parent = c
					tool.draggedParts[i] = dragged
					ms.play(ms.hover())
				end
			end
			
			for i = parts + 1, #tool.draggedParts do
				tool.draggedParts[i]:Destroy()
				tool.draggedParts[i] = nil
				ms.play(ms.hover())
			end
			
			if normal ~= tool.lastDraggedNormal then
				for i = 1, #tool.draggedParts do
					tool.draggedParts[i]:Destroy()
					tool.draggedParts[i] = nil
				end
			end
			
			tool.lastDraggedNormal = normal
		end
		
		if part == nil and tool.placing and not tool.dragging then
			tool.placing:Destroy()
			tool.placing = nil
			--tool.placingRotation = 0
			return
		end
		
		if part == nil and not tool.dragging then
			return
		end
		
		local w, h, d = size.X, size.Y, size.Z
		local myPos = hit + (normal * 0.5) * size
		
		tool.placingCFrame = CFrame.new(Vector3.new(
			math.floor(myPos.X + (w % 2 == 0 and 0.5 or 0)) + (w % 2 == 1 and 0.5 or 0) + tool.nudge.x,
			math.floor(myPos.Y * 3 + (h * 3 % 2 == 0 and 0.5 or 0)) / 3 + (math.floor(h * 3 % 2 + 0.5) == 1 and 1/6 or 0),
			math.floor(myPos.Z + (d % 2 == 0 and 0.5 or 0)) + (d % 2 == 1 and 0.5 or 0) + tool.nudge.z
		))
		tool.placingCFrame = tool.placingCFrame * CFrame.Angles(0, math.pi / 2 * -tool.placingRotation, 0)
		
		if tool.dragging then
			tool.placingCFrame = CFrame.new(tool.placingOrigin) * CFrame.Angles(0, math.pi / 2 * -tool.placingRotation, 0)
		end
		
		if not tool.placing then
			tool.nudge = {x = 0, z = 0}
			tool.placing = bg.createStandardBrick(tool.hotbar[tool.selected], tool.color)
			for i,v in next, tool.placing:GetChildren() do
				if v:IsA("BasePart") then
					v.CanCollide = false
					v.Transparency = v.Transparency + 0.3
				end
			end
			tool.placing:SetPrimaryPartCFrame(tool.placingCFrame)
			tool.placing.Parent = c
			blinkTimer = math.pi
		end
		
		blinkTimer = blinkTimer + delta
		if blinkTimer > math.pi * 2 then
			blinkTimer = blinkTimer - math.pi * 2
		end
		tool.placing:SetPrimaryPartCFrame(tool.placing:GetPrimaryPartCFrame():lerp(tool.placingCFrame, 0.5))
		for i,v in next, tool.placing:GetChildren() do
			if v:IsA("BasePart") then
				v.Color = tool.dragging and tool.color.color3 or tool.color.color3:lerp(Color3.new(1, 1, 1), math.pow(math.sin(time() * 3), 16) / 2)
			end
		end
	else
		if tool.placing then
			tool.placing:Destroy()
			tool.placing = nil
		end
	end
end)

return tool
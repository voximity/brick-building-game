local load = require(game:GetService("ReplicatedStorage").Shared.Load)(script)
---------------------------------------------------------------------------------
local bg, big = load("/Shared/BrickGenerator"), load("../../BrickIconGenerator")
local usd = load("/Shared/UserdataDeserializer")
local ms = load("/Shared/MenuSound")
local kb = load("../../Keyboard")
local colors = load("/Shared/Colors")
local network = load("/Shared/Network")

local me = game.Players.LocalPlayer

local input = game:GetService("UserInputService")

local tool = {}
tool.active = false
tool.step = 0

-- Steps:
--- 0: Start by selecting a baseplate
--- 1: Select any more adjacent baseplates
--- 2: Name your save file

tool.ui = nil
tool.selected = {}

tool.createSaveUi = function(ui)
	local f = Instance.new("Frame")
	tool.ui = f
	f.BackgroundTransparency = 1
	f.Size = UDim2.new(0, 450, 0, 150)
	f.Position = UDim2.new(0.5, -450 / 2, 0, 100)
	f.Visible = false
	
	local title = Instance.new("TextLabel")
	title.Text = "Select a baseplate"
	title.Name = "Title"
	title.Font = "GothamBold"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextStrokeTransparency = 0
	title.TextStrokeColor3 = Color3.new(0, 0, 0)
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 40)
	title.TextSize = 38
	title.Parent = f
	
	local subtitle = title:Clone()
	subtitle.Text = "It must be touching the main baseplate"
	subtitle.Name = "Subtitle"
	subtitle.Font = "Gotham"
	subtitle.TextSize = 18
	subtitle.Size = UDim2.new(1, 0, 1, -50)
	subtitle.Position = UDim2.new(0, 0, 0, 50)
	subtitle.TextYAlignment = "Top"
	subtitle.TextWrapped = true
	subtitle.Parent = f
	
	f.Parent = ui
end
local startedSaving = false

tool.open = function()
	if tool.tools.freecam.active then return end
	if tool.tools.build.dragging then return end
	tool.tools.build.close()
	tool.tools.paint.close()
	tool.tools.remove.close()
	tool.tools.wrench.close()
	startedSaving = false
	
	tool.ui.Visible = true
	tool.active = true
	tool.selected = {}
	tool.placing = false
end
tool.close = function()
	if tool.savesMenuActive then tool.stopSavesMenu() end
	tool.selector.Parent = nil
	tool.ui.Visible = false
	tool.active = false
	tool.savesMenuActive = false
	tool.selected = {}
end

tool.savesMenu = nil
tool.savesMenuActive = false
tool.stopSavesMenu = function()
	input.MouseBehavior = Enum.MouseBehavior.LockCenter
	tool.savesMenuActive = false
	if tool.savesMenu then
		local sm = tool.savesMenu
		pcall(function() sm:TweenPosition(tool.savesMenu.Position - UDim2.new(0, 0, 1, 0), "InOut", "Quint", 0.3, true) end)
		delay(0.3, function() sm:Destroy() end)
	end
end
tool.placing = false
tool.placingSize = Vector3.new()
tool.placingCFrame = CFrame.new()
tool.placingSaveName = nil
tool.placingRotation = 0

local requestedPlacing = false

tool.showSavesMenu = function(isSavingNow)
	tool.savesMenuActive = true
	
	local saves = network.invoke("get saves")
	if not saves then error("NO GET SAVES!!!! CONTACT A DEVELOPER") end
	
	local menu = script.SavesList:Clone()
	tool.savesMenu = menu
	local pos = menu.Position
	menu.Position = pos - UDim2.new(0, 0, 1, 0)
	
	local saveFrame = menu.Scroller.Save:Clone()
	menu.Scroller.Save:Destroy()
	local isSaving = false
	
	local saveButtonFunctionality = function(name)
		if not isSaving then
			isSaving = true
			
			local s,e = pcall(function() tool.save(name) end)
			if s then
				tool.notification.show("Saved to \"" .. name .. "\".")
			else
				tool.notification.show("Failed to save. You may have too many bricks, or there could be an internal server error.", true)
			end
			tool.stopSavesMenu()
		end
	end
	
	for i,v in next, saves do
		local sf = saveFrame:Clone()
		sf.SaveName.Text = v.name
		sf.SaveBrickCount.Text = v.total .. " bricks"
		sf.SaveDate.Text = string.gsub("{month}/{day}/{year} {hour}:{min}", "{(%w+)}", os.date("*t", v.modified))
		sf.Parent = menu.Scroller
		
		if not isSavingNow then
			sf.OverwriteButton.Text = "Load"
			sf.OverwriteButton.MouseButton1Down:connect(function()
				if not tool.savesMenuActive then return end
				requestedPlacing = false
				tool.placing = true
				tool.placingSize = usd.vector3(v.size)
				tool.placingSaveName = v.name
				tool.stopSavesMenu()
			end)
		end
		
		local isDeleting = false
		sf.DeleteButton.MouseButton1Down:connect(function()
			if not isDeleting then
				isDeleting = true
				
				local s,e = pcall(function() network.invoke("remove save", v.name) end)
				if s then
					sf:Destroy()
					tool.notification.show("Deleted save \"" .. v.name .. "\".")
				else
					tool.notification.show("Failed to delete save.", true)
					tool.stopSavesMenu()
				end
			end
		end)
		
		if isSavingNow then
			sf.OverwriteButton.MouseButton1Down:connect(function()
				saveButtonFunctionality(v.name)
			end)
		end
	end
	
	if isSavingNow then
		menu.Button.Text = "New Save"
		menu.Button.MouseButton1Down:connect(function()
			saveButtonFunctionality("Save #" .. (#saves + 1))
		end)
	else
		menu.Button.Text = "Close"
		menu.Button.MouseButton1Down:connect(function()
			if not tool.savesMenuActive then return end
			tool.stopSavesMenu()
		end)
	end
	
	menu.Parent = tool.ui.Parent
	input.MouseBehavior = Enum.MouseBehavior.Default
	menu:TweenPosition(pos, "InOut", "Quint", 0.3, true)
end

kb.bind("x", function()
	if tool.active then
		--tool.close()
		if tool.savesMenuActive then
			tool.stopSavesMenu()
		else
			tool.showSavesMenu()
		end
	else
		tool.open()
	end
end)

tool.selector = Instance.new("Part")
tool.selector.Anchored = true
tool.selector.CanCollide = false
tool.selector.FormFactor = "Custom"
tool.selector.Transparency = 1

local sbox = Instance.new("SelectionBox")
sbox.Adornee = tool.selector
sbox.Color3 = Color3.new(0, 0, 1)
sbox.LineThickness = 0.01
sbox.Parent = tool.selector

tool.canPlace = false

local selectorNeedsUpdating = false

function checkForIntersection(position, size)
	local off = Vector3.new(0.1, 0.1, 0.1)
	local parts = workspace:FindPartsInRegion3WithIgnoreList(Region3.new(position - (size - off) / 2, position + (size - off) / 2), {game.Players.LocalPlayer.Character, workspace.CurrentCamera, unpack(tool.tools.remove.sparkList or {})})
	return #parts > 0
end

input.InputEnded:connect(function(io)
	if io.UserInputType == Enum.UserInputType.MouseButton1 and tool.active and not tool.placing and not tool.savesMenuActive then
		local cam = workspace.CurrentCamera
		local ray = Ray.new(cam.CFrame.p, cam.CFrame.lookVector * 50)
		local part, hit = workspace:FindPartOnRayWithIgnoreList(ray, {cam, me.Character, unpack(tool.tools.remove.sparkList)})
		
		if not part then return end
		if part == workspace.Base then
			tool.notification.show("You can't select the main baseplate as grounds for saving.", true)
			return
		end
		part = part.Parent
		if part.Name ~= "Brick" or not part:FindFirstChild("Owner") then
			tool.notification.show("You must select a valid brick.", true)
		elseif part:FindFirstChild("Owner") and part.Owner.Value ~= me then
			tool.notification.show("You must select one of your baseplates.", true)
		elseif part:FindFirstChild("Owner") and part.Owner.Value == me and not part:FindFirstChild("Baseplate") then
			tool.notification.show("You must select a baseplate.", true)
		elseif part:FindFirstChild("Owner") and part.Owner.Value == me and part:FindFirstChild("Baseplate") and part.Supported.Value ~= workspace.Base then
			tool.notification.show("The baseplate must be supported by the main ground baseplate.", true)
		elseif part:FindFirstChild("Owner") and part.Owner.Value == me and part:FindFirstChild("Baseplate") and part.Supported.Value == workspace.Base then
			-- valid baseplate, select it
			local removed = false
			for i = #tool.selected, 1, -1 do
				if tool.selected[i] == part then
					table.remove(tool.selected, i)
					removed = true
					break
				end
			end
			if not removed and #tool.selected < 10 then
				table.insert(tool.selected, part)
			end
			selectorNeedsUpdating = true
		end
	elseif io.UserInputType == Enum.UserInputType.MouseButton2 and tool.active and tool.canSave and #tool.selected > 0 and not tool.tooBig then
		if not startedSaving then
			startedSaving = true
			tool.showSavesMenu(true)
		end
	elseif io.UserInputType == Enum.UserInputType.MouseButton1 and tool.active and tool.placing and tool.selector.Parent and (not tool.savesMenu or not tool.savesMenu.Parent) and tool.canPlace then
		if checkForIntersection(tool.placingCFrame.p, tool.placingSize) then tool.notification.show("An intersection occured when trying to place this save.", true) return end
		if not requestedPlacing then
			requestedPlacing = true
			tool.placing = false
			tool.selector.Parent = nil
			tool.selected = {}
			local result = network.invoke("place save", tool.placingSaveName, tool.placingCFrame.p)
			requestedPlacing = false
		end
	end
end)

tool.getBrickSize = function(brick)
	local ry = brick.PrimaryPart.Orientation.Y
	local rot = math.abs(math.floor(ry / 90 + 0.5))
	return rot % 2 == 1 and Vector3.new(brick.PrimaryPart.Size.Z, brick.PrimaryPart.Size.Y, brick.PrimaryPart.Size.X) or brick.PrimaryPart.Size
end
tool.corners = function(pos, size)
	local c1 = pos - size / 2
	local c2 = pos + size / 2
	local min, max = math.min, math.max
	return
		Vector3.new(min(c1.X, c2.X), min(c1.Y, c2.Y), min(c1.Z, c2.Z)),
		Vector3.new(max(c1.X, c2.X), max(c1.Y, c2.Y), max(c1.Z, c2.Z))
end
tool.averagePosition = function(...)
	local minX, minY, minZ = math.huge, math.huge, math.huge
	local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
	local min, max = math.min, math.max
	
	for i,v in next, {...} do
		local c1, c2 = tool.corners(v:GetPrimaryPartCFrame().p, tool.getBrickSize(v))
		
		minX, minY, minZ = min(minX, c1.X), min(minY, c1.Y), min(minZ, c1.Z)
		maxX, maxY, maxZ = max(maxX, c2.X), max(maxY, c2.Y), max(maxZ, c2.Z)
	end
	
	return Vector3.new((minX + maxX) / 2, (minY + maxY) / 2, (minZ + maxZ) / 2)
end
tool.getExtentsSize = function(...)
	local minX, minY, minZ = math.huge, math.huge, math.huge
	local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
	local min, max = math.min, math.max
	
	for i,v in next, {...} do
		local c1, c2 = tool.corners(v:GetPrimaryPartCFrame().p, tool.getBrickSize(v))
		
		minX, minY, minZ = min(minX, c1.X), min(minY, c1.Y), min(minZ, c1.Z)
		maxX, maxY, maxZ = max(maxX, c2.X), max(maxY, c2.Y), max(maxZ, c2.Z)
	end
	
	return Vector3.new(maxX - minX, maxY - minY, maxZ - minZ)
end
tool.getSupportedParts = function(p)
	local parts = {}
	local function rec(x)
		for i,v in next, x:GetChildren() do
			if v.Name == "Supporting" then
				table.insert(parts, v.Value)
				rec(v.Value)
			end
		end
	end
	rec(p)
	return parts
end
tool.getAllSelectedParts = function()
	local all = {}
	for i,v in next, tool.selected do
		table.insert(all, v)
		for a,b in next, tool.getSupportedParts(v) do
			table.insert(all, b)
		end
	end
	
	return all
end
tool.encodeSaveData = function(mainPos, allBricks)
	local saveData = {}
	local function getBrickIndex(b)
		for i,v in next, allBricks do
			if v == b then
				return i
			end
		end
	end
	
	for i,v in next, allBricks do
		local data = {}
		data.id = v.BrickId.Value
		data.position = v:GetPrimaryPartCFrame().p - mainPos
		data.position = Vector3.new(math.floor(data.position.X * 10 + 0.5) / 10, data.position.Y, math.floor(data.position.Z * 10 + 0.5) / 10)
		data.position = "(" .. data.position.X .. "," .. data.position.Y .. "," .. data.position.Z .. ")"
		local orient = v.PrimaryPart.Orientation.Y
		if orient < 0 then orient = 360 + orient end
		data.rotation = math.abs(math.floor(orient / 90 + 0.5))
		data.supported = v.Supported.Value == workspace.Base and "base" or getBrickIndex(v.Supported.Value)
		data.supporting = {}
		
		for a,b in next, v:GetChildren() do
			if b.Name == "Supporting" and b.Value then
				table.insert(data.supporting, getBrickIndex(b.Value))
			end
		end
		
		local c3 = v.PrimaryPart.Color
		data.color = {
			brickColor = v.PrimaryPart.BrickColor.Name,
			color3 = "(" .. c3.r .. "," .. c3.g .. "," .. c3.b .. ")",
			trans = v.PrimaryPart.Transparency,
			material = v.PrimaryPart.Material.Name}
		
		saveData[i] = data
	end
	
	return saveData
end

tool.save = function(name)
	local bricks = tool.getAllSelectedParts()
	local size = tool.getExtentsSize(unpack(bricks))
	local pos = tool.averagePosition(unpack(bricks))
	local saveData = tool.encodeSaveData(pos, bricks)
	network.invoke("save", #tool.selected, #bricks, size, saveData, name)
	
	tool.selected = {}
	tool.selector.Parent = nil
	tool.canSave = true
	tool.tooBig = false
	startedSaving = false
	requestedPlacing = false
end

local allParts = {}

tool.canSave = true
tool.tooBig = false

game:GetService("RunService").RenderStepped:connect(function()
	local cam = workspace.CurrentCamera
	if tool.active and not tool.placing then
		
		if #tool.selected == 0 then
			tool.ui.Title.Text = "Select a baseplate"
			tool.ui.Subtitle.Text = "It must be touching the main baseplate"
		elseif #tool.selected > 0 and #tool.selected < 10 then
			tool.ui.Title.Text = "Select more baseplates"
			tool.ui.Subtitle.Text = "Or, you can choose to save what you have selected by right-clicking"
			tool.tooBig = false
		elseif #tool.selected == 10 then
			tool.ui.Title.Text = "Selected maximum of 10"
			tool.ui.Subtitle.Text = "You can't select any more baseplates. Finalize saving by right-clicking"
			tool.tooBig = true
		end
		
		if #tool.selected > 0 then
			if selectorNeedsUpdating or tool.selector.Parent == nil then
				allParts = tool.getAllSelectedParts()
			end
			
			local selectorCFrame = CFrame.new(tool.averagePosition(unpack(allParts)))
			local selectorSize = tool.getExtentsSize(unpack(allParts))
			
			local baseSizeMagnitude = (tool.getExtentsSize(unpack(tool.selected)) * Vector3.new(1, 0, 1)).magnitude
			local totalSizeMagnitude = (selectorSize * Vector3.new(1, 0, 1)).magnitude
			
			if totalSizeMagnitude > baseSizeMagnitude + 10 then
				tool.ui.Title.Text = "Extents exceeded"
				tool.ui.Subtitle.Text = "The bricks on the baseplates are too far off of the baseplate to save.\nKeep them within the bounds of the baseplate."
				tool.canSave = false
			else
				tool.canSave = true
			end
			
			if tool.selector.Parent == nil then
				tool.selector.Parent = cam
				tool.selector.CFrame = selectorCFrame
				tool.selector.Size = selectorSize
				selectorNeedsUpdating = false
			else
				if selectorNeedsUpdating then
					local tween = game:GetService("TweenService"):Create(tool.selector, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {
						CFrame = selectorCFrame,
						Size = selectorSize
					})
					tween:Play()
					selectorNeedsUpdating = false
				end
			end
		else
			tool.selector.Parent = nil
		end
	elseif tool.active and tool.placing then
		
		tool.ui.Title.Text = "Select a pasting spot"
		tool.ui.Subtitle.Text = "When you find a spot, click, and the save will be loaded into that spot."
		
		local ray = Ray.new(cam.CFrame.p, cam.CFrame.lookVector * 200)
		local part, hit, normal = workspace:FindPartOnRayWithWhitelist(ray, {workspace.Base})
		
		if part == nil then
			tool.selector.Parent = nil
		end
		
		if part then
			tool.canPlace = true
		else
			tool.canPlace = false
		end
		
		local size = tool.placingSize
		
		local w, h, d = size.X, math.floor((size.Y - math.floor(size.Y)) * 10) / 10 % 0.3 == 0 and math.floor(size.Y * 3 + 0.5) / 3 or size.Y, size.Z
		local myPos = hit + (normal * 0.5) * size
		
		tool.placingCFrame = CFrame.new(Vector3.new(
			math.floor(myPos.X + (w % 2 == 0 and 0.5 or 0)) + (w % 2 == 1 and 0.5 or 0),
			math.floor(myPos.Y * 3 + (h * 3 % 2 == 0 and 0.5 or 0)) / 3 + (math.floor(h * 3 % 2 + 0.5) == 1 and 1/6 or 0),
			math.floor(myPos.Z + (d % 2 == 0 and 0.5 or 0)) + (d % 2 == 1 and 0.5 or 0)
		))
		tool.placingCFrame = tool.placingCFrame * CFrame.Angles(0, math.pi / 2 * -tool.placingRotation, 0)
		
		if tool.selector.Parent then
			tool.selector.CFrame = tool.selector.CFrame:lerp(tool.placingCFrame, 0.5)
		end
		
		if not tool.selector.Parent then
			tool.selector.Parent = cam
			tool.selector.Size = tool.placingSize
			tool.selector.CFrame = tool.placingCFrame
		end
	end
end)

return tool
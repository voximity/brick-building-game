local load = require(game:GetService("ReplicatedStorage").Shared.Load)(script)
---------------------------------------------------------------------------------
local bg, big = load("/Shared/BrickGenerator"), load("../../BrickIconGenerator")
local ms = load("/Shared/MenuSound")
local kb = load("../../Keyboard")
local network = load("/Shared/Network")
local colors = load("/Shared/Colors")

local assets = game:GetService("ReplicatedStorage").Assets

local tool = {}
tool.tools = {}

tool.notification = nil

tool.active = false
tool.row = 1
tool.column = 1

tool.pickerSize = 20

tool.ui = nil

tool.createPaintUi = function(p)
	local f = Instance.new("Frame")
	tool.ui = f
	local longestRow = 0
	
	for rowIndex, row in next, colors.list do
		local container = Instance.new("Frame")
		container.Name = tostring(rowIndex)
		container.Size = UDim2.new(0, tool.pickerSize, 0, tool.pickerSize * #row)
		container.Position = UDim2.new(0, tool.pickerSize * (rowIndex - 1), 0, 0)
		container.BackgroundTransparency = 1
		
		local label = Instance.new("TextLabel")
		label.Text = row[1]
		label.Font = "SourceSansBold"
		label.TextSize = tool.pickerSize - 2
		label.TextXAlignment = "Left"
		label.BackgroundTransparency = 1
		label.Rotation = -90-- -60
		label.TextStrokeTransparency = 0
		label.TextStrokeColor3 = Color3.new(0, 0, 0)
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Size = UDim2.new(0, tool.pickerSize, 0, 0)
		label.Position = UDim2.new(0, 0, 0, -16)
		label.Parent = container
		
		if longestRow < #row[2] then
			longestRow = #row[2]
		end
		
		for columnIndex, color in next, row[2] do
			local picker = Instance.new("Frame")
			picker.Name = tostring(columnIndex)
			picker.Size = UDim2.new(0, tool.pickerSize, 0, tool.pickerSize)
			picker.Position = UDim2.new(0, 0, 0, (columnIndex - 1) * tool.pickerSize)
			picker.BorderSizePixel = 0
			picker.BackgroundColor3 = color.color3
			picker.BackgroundTransparency = color.trans
			picker.BorderColor3 = Color3.new(1, 1, 1)
			picker.Parent = container
		end
		
		container.Parent = f
	end
	
	f.Size = UDim2.new(0, tool.pickerSize * #colors.list, 0, tool.pickerSize * longestRow)
	f.Position = UDim2.new(0, 10, 1, f.Size.Y.Offset + 10)
	f.BackgroundTransparency = 1
	f.Parent = p
	
	tool.updateUi()
	
	return f
end

tool.viewmodel = function()
	return tool.vm.current.model
end

tool.updateUi = function()
	local rowElement = tool.ui:FindFirstChild(tostring(tool.row))
	local columnElement = rowElement:FindFirstChild(tostring(tool.column))
	
	for i = 1, #colors.list do
		local r = tool.ui:FindFirstChild(tostring(i))
		r.TextLabel.TextColor3 = Color3.new(0.6, 0.6, 0.6)
		for x = 1, #colors.list[i][2] do
			r:FindFirstChild(tostring(x)).BorderSizePixel = 0
			r:FindFirstChild(tostring(x)).ZIndex = 1
		end
	end
	
	rowElement.TextLabel.TextColor3 = Color3.new(1, 1, 1)
	columnElement.ZIndex = 2
	columnElement.BorderSizePixel = 4
	
	tool.tools.build.color = colors.list[tool.row][2][tool.column]
	tool.tools.build.createInventory(tool.tools.build.invUi)
	
	local c3 = tool.tools.build.color.color3
	if tool.vm.current.model then
		--[[local muzzle = tool.viewmodel():FindFirstChild("Muzzle")
		tool.viewmodel():FindFirstChild("Indicator").Color = tool.tools.build.color.color3
		muzzle.ParticleEmitter.Color = ColorSequence.new(tool.tools.build.color.color3)
		
		muzzle.R.Color = ColorSequence.new(Color3.new(muzzle.ParticleEmitter.Color.Keypoints[1].Value.r, 0, 0))
		muzzle.G.Color = ColorSequence.new(Color3.new(0, muzzle.ParticleEmitter.Color.Keypoints[1].Value.g, 0))
		muzzle.B.Color = ColorSequence.new(Color3.new(0, 0, muzzle.ParticleEmitter.Color.Keypoints[1].Value.b))]]
		local view = tool.viewmodel()
		local muzzle = view:FindFirstChild("Muzzle")
		local indicator = view:FindFirstChild("Indicator")
		local tween = game:GetService("TweenService")
		local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
		
		tween:Create(indicator, tweenInfo, {Color = c3}):Play()
		
		muzzle.ParticleEmitter.Color = ColorSequence.new(tool.tools.build.color.color3)
		muzzle.R.Color = ColorSequence.new(Color3.new(muzzle.ParticleEmitter.Color.Keypoints[1].Value.r, 0, 0))
		muzzle.G.Color = ColorSequence.new(Color3.new(0, muzzle.ParticleEmitter.Color.Keypoints[1].Value.g, 0))
		muzzle.B.Color = ColorSequence.new(Color3.new(0, 0, muzzle.ParticleEmitter.Color.Keypoints[1].Value.b))
	end
end

tool.open = function()
	if tool.tools.freecam.active then return end
	if tool.tools.build.dragging then return end
	tool.vm.create(assets.Tools.PaintGun)
	tool.updateUi()
	tool.active = true
	tool.ui:TweenPosition(UDim2.new(0, 10, 1, -tool.ui.Size.Y.Offset - 10), "Out", "Quint", 0.3, true)
end

tool.close = function()
	tool.vm.stop()
	tool.active = false
	tool.ui:TweenPosition(UDim2.new(0, 10, 1, tool.ui.Size.Y.Offset + 10), "In", "Quint", 0.3, true)
end

kb.bind("e", function()
	if tool.tools.freecam.active then return end
	tool.tools.build.close()
	tool.tools.remove.close()
	tool.tools.save.close()
	tool.tools.wrench.close()
	if not tool.active then
		tool.open()
	else
		tool.row = tool.row + 1
		if tool.row > #colors.list then
			tool.row = 1
		end
		if tool.column > #colors.list[tool.row][2] then
			tool.column = #colors.list[tool.row][2]
		end
		tool.vm.playAnimation({
			{duration = 0.05, pos = CFrame.new(0, 0.2, 0), angle = CFrame.Angles(math.rad(-8), 0, 0)},
			{duration = 0.05, pos = CFrame.new(), angle = CFrame.new()}
		})
		tool.updateUi()
	end
end)

tool.colorPick = function(part)
	for r,cat in next, colors.list do
		for c,v in next, cat[2] do
			if v.color3 == part.Color and v.material == part.Material then
				tool.row = r
				tool.column = c
				tool.updateUi()
				break
			end
		end
	end
end

local input = game:GetService("UserInputService")

tool.clicking = false

input.InputBegan:connect(function(io)
	if tool.active and io.UserInputType == Enum.UserInputType.MouseButton1 then
		tool.clicking = true
		tool.viewmodel().Muzzle.Sound:Play()
	elseif tool.active and io.UserInputType == Enum.UserInputType.MouseButton2 then
		-- color pick
		local c = workspace.CurrentCamera
		local ray = Ray.new(c.CFrame.p, c.CFrame.lookVector * 15)
		local part, hit = workspace:FindPartOnRayWithIgnoreList(ray, {c, game.Players.LocalPlayer.Character})
		
		if part then
			tool.colorPick(part)
		end
	end
end)

input.InputEnded:connect(function(io)
	if tool.active and io.UserInputType == Enum.UserInputType.MouseButton1 then
		tool.clicking = false
		tool.viewmodel().Muzzle.Sound:Stop()
	end
end)

local lastpainted = nil

game:GetService("RunService").RenderStepped:connect(function()
	if tool.active then
		tool.vm.current.model:FindFirstChild("Muzzle").ParticleEmitter.Enabled = tool.clicking
		
		if tool.clicking then
			local c = workspace.CurrentCamera
			local ray = Ray.new(c.CFrame.p, c.CFrame.lookVector * 15)
			local part, hit = workspace:FindPartOnRayWithIgnoreList(ray, {c, game.Players.LocalPlayer.Character})
			
			if part and part.Parent and part.Parent.Name == "Brick" and lastpainted ~= part then
				if part.Parent:FindFirstChild("Owner") and part.Parent.Owner.Value == game.Players.LocalPlayer then
					network.send("brick color", part.Parent, tool.tools.build.color)
				else
					tool.notification.show("You can't paint that brick because " .. part.Parent.Owner.Value.Name .. " owns it.", true)
				end
			end
			
			if part then
				lastpainted = part.Parent
			end
		end
	else
		tool.clicking = false
	end
end)

input.InputChanged:connect(function(io)
	if tool.active and io.UserInputType == Enum.UserInputType.MouseWheel then
		tool.column = tool.column - io.Position.Z
		if tool.column > #colors.list[tool.row][2] then
			tool.column = 1
		end
		if tool.column < 1 then
			tool.column = #colors.list[tool.row][2]
		end
		tool.vm.playAnimation({
			{duration = 0.04, pos = CFrame.new(), angle = CFrame.Angles(0, 0, math.rad(io.Position.Z) * 15)},
			{duration = 0.04, pos = CFrame.new(), angle = CFrame.new()}
		})
		tool.updateUi()
	end
end)

return tool
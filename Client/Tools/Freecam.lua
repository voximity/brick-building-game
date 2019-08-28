local load = require(game:GetService("ReplicatedStorage").Shared.Load)(script)
---------------------------------------------------------------------------------
local kb = load("../../Keyboard")
local network = load("/Shared/Network")

local ctxaction = game:GetService("ContextActionService")
local input = game:GetService("UserInputService")

local fc = {}
fc.active = false

fc.cam = workspace.CurrentCamera
fc.cframe = CFrame.new()
fc.localVelocity = Vector3.new()
fc.delta = {x = 0, y = 0}
fc.rot = {x = 0, y = 0}
fc.keyVelocity = {w = false, s = false, a = false, d = false, space = false, shift = false}
fc.zoom = 90
fc.disabledUi = {}
fc.disabledCoreGui = {}

fc.enable = function()
	if fc.active then return end
	
	fc.tools.build.close()
	fc.tools.paint.close()
	fc.tools.remove.close()
	fc.tools.save.close()
	fc.tools.wrench.close()
	
	fc.active = true
	input.MouseBehavior = Enum.MouseBehavior.LockCenter
	fc.cam.CameraType = Enum.CameraType.Scriptable
	ctxaction:BindAction("freezeMovement", function() return Enum.ContextActionResult.Sink end, false, unpack(Enum.PlayerActions:GetEnumItems()))
	fc.cframe = fc.cam.CFrame
	fc.delta = {x = 0, y = 0}
	fc.rot = {x = 0, y = 0}
	fc.zoom = 90
	
	fc.disabledUi = {}
	fc.disabledCoreGui = {}
	input.MouseIconEnabled = false
	for i,v in next, game.Players.LocalPlayer.PlayerGui:GetChildren() do
		v.Enabled = false
		table.insert(fc.disabledUi, v)
	end
	
	for i,v in next, Enum.CoreGuiType:GetEnumItems() do
		if v ~= Enum.CoreGuiType.All and game:GetService("StarterGui"):GetCoreGuiEnabled(v) then
			table.insert(fc.disabledCoreGui, v)
		end
	end
	game:GetService("StarterGui"):SetCoreGuiEnabled("All", false)
	game:GetService("StarterGui"):SetCore("TopbarEnabled", false)
end

fc.disable = function()
	if not fc.active then return end
	
	fc.active = false
	fc.cam.CameraType = Enum.CameraType.Custom
	fc.cam.FieldOfView = 90
	ctxaction:UnbindAction("freezeMovement")
	
	game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
	input.MouseIconEnabled = true
	for i,v in next, fc.disabledUi do
		v.Enabled = true
	end
	game:GetService("StarterGui"):SetCore("TopbarEnabled", true)
	for i,v in next, fc.disabledCoreGui do
		game:GetService("StarterGui"):SetCoreGuiEnabled(v, true)
	end
end

network.on("freecam", function()
	fc.enable()
end)

kb.bind("w", function() fc.keyVelocity.w = true end, function() fc.keyVelocity.w = false end)
kb.bind("s", function() fc.keyVelocity.s = true end, function() fc.keyVelocity.s = false end)
kb.bind("a", function() fc.keyVelocity.a = true end, function() fc.keyVelocity.a = false end)
kb.bind("d", function() fc.keyVelocity.d = true end, function() fc.keyVelocity.d = false end)
kb.bind("space", function() fc.keyVelocity.space = true end, function() fc.keyVelocity.space = false end)
kb.bind("leftshift", function() fc.keyVelocity.shift = true end, function() fc.keyVelocity.shift = false end)

kb.bind("return", function()
	if not fc.active then return end
	
	fc.disable()
end)

function lerp(a, b, c) return a + (b - a) * c end

input.InputChanged:connect(function(io)
	if io.UserInputType == Enum.UserInputType.MouseMovement and fc.active then
		fc.delta = {x = io.Delta.X, y = io.Delta.Y}
	elseif io.UserInputType == Enum.UserInputType.MouseWheel and fc.active then
		fc.zoom = math.min(math.max(fc.zoom - io.Position.Z * 4, 15), 120)
	end
end)

game:GetService("RunService").RenderStepped:connect(function(delta)
	if fc.active then
		local mouseDelta = input.MouseDeltaSensitivity / 2
		local lf = delta / (1 / 60)
		
		input.MouseBehavior = Enum.MouseBehavior.LockCenter
		local w, s, a, d, space, shift =
			fc.keyVelocity.w and 1 or 0,
			fc.keyVelocity.s and 1 or 0,
			fc.keyVelocity.a and 1 or 0,
			fc.keyVelocity.d and 1 or 0,
			fc.keyVelocity.space and 1 or 0,
			fc.keyVelocity.shift and 1 or 0
		
		fc.cam.FieldOfView = lerp(fc.cam.FieldOfView, fc.zoom, 0.2 * lf)
		local fovFactor = fc.cam.FieldOfView / 90
		
		fc.localVelocity = Vector3.new((d - a) / 5 * lf, (space - shift) / 5 * lf, (s - w) / 5 * lf)
		fc.rot.x = math.min(math.max(fc.rot.x - fc.delta.y * fovFactor * mouseDelta, -80), 80)
		fc.rot.y = fc.rot.y - fc.delta.x * fovFactor * mouseDelta
		fc.cframe = CFrame.new(fc.cframe.p) * CFrame.fromEulerAnglesYXZ(math.rad(fc.rot.x), math.rad(fc.rot.y), 0) * CFrame.new(fc.localVelocity)
		fc.delta = {x = 0, y = 0}
		
		fc.cam.CFrame = fc.cam.CFrame:lerp(fc.cframe, 0.2 * lf)
	end
end)

return fc
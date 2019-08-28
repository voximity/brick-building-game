local load = require(game:GetService("ReplicatedStorage").Shared.Load)(script)
---------------------------------------------------------------------------------

local bg = load("/Shared/BrickGenerator")
local network = load("/Shared/Network")
local big = load("./BrickIconGenerator")
local notification = load("./Notifications")
local cp = load("./Content")
local vm = load("./Viewmodel")
local sr = load("./ServerReplicator")
local tools = load("./Tools")(vm)
local fig = load("./MinifigRender")
local chat = load("./Chat")

local sg = Instance.new("ScreenGui")
sg.ResetOnSpawn = false
sg.Name = "GameUi"
sg.Parent = game.Players.LocalPlayer.PlayerGui

tools.build.notification = notification
tools.build.createHotbar(sg)

tools.paint.notification = notification
tools.paint.createPaintUi(sg)

tools.save.notification = notification
tools.save.createSaveUi(sg)

tools.remove.notification = notification

notification.init().Parent = game.Players.LocalPlayer.PlayerGui

local ui = {screen = sg}
local chat = load("./Chat")(ui)
chat.tools = tools
chat.init()

workspace.CurrentCamera.FieldOfView = 90
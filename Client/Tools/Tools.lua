local load = require(game:GetService("ReplicatedStorage").Shared.Load)(script)
---------------------------------------------------------------------------------
local network = load("/Shared/Network")

local tools = {}

tools.trustedBy = {}

tools.build = require(script.ToolBuild)
tools.paint = require(script.ToolPaint)
tools.remove = require(script.ToolRemove)
tools.save = require(script.ToolSave)
tools.wrench = require(script.ToolWrench)
tools.freecam = require(script.Freecam)

tools.build.tools = tools
tools.paint.tools = tools
tools.remove.tools = tools
tools.save.tools = tools
tools.wrench.tools = tools
tools.freecam.tools = tools

function indexOf(t, v)
	for i,x in next, t do
		if x == v then
			return i
		end
	end
end

network.on("trusted by", function(player)
	if not indexOf(tools.trustedBy, player) then
		table.insert(tools.trustedBy, player)
	end
end)

game.Players.PlayerRemoving:connect(function(p)
	if indexOf(tools.trustedBy, p) then
		table.remove(tools.trustedBy, indexOf(tools.trustedBy))
	end
end)

game:GetService("UserInputService").InputBegan:connect(function(io)
	if io.UserInputType == Enum.UserInputType.MouseButton1 and not tools.build.active and not tools.paint.active and not tools.remove.active then
		local c = workspace.currentCamera
		local p, h = workspace:FindPartOnRayWithIgnoreList(Ray.new(c.CFrame.p, c.CFrame.lookVector * 10), {c, game.Players.LocalPlayer.Character})
		if p then network.send("activate", p) end
	end
end)

return function(vm) tools.vm = vm tools.build.vm = vm tools.paint.vm = vm tools.save.vm = vm tools.wrench.vm = vm return tools end
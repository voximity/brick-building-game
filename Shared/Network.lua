local network = {}

network.isClient = game:GetService("RunService"):IsClient()
network.isServer = game:GetService("RunService"):IsServer()

network.binds = {}
network.funcBinds = {}

network.event = function()
	local e = game:GetService("ReplicatedStorage"):FindFirstChild("Event")
	return e
end
network.func = function()
	local f = game:GetService("ReplicatedStorage"):FindFirstChild("Function")
	return f
end

network.invoke = function(x, y, ...)
	if network.isClient then
		return network.func():InvokeServer(x, unpack({y, ...}))
	elseif network.isServer then
		return network.func():InvokeClient(x, ...)
	end
end

network.send = function(x, y, ...)
	if network.isClient then
		local action = x
		local args = {y, ...}
		
		network.event():FireServer(action, unpack(args))
	elseif network.isServer then
		local target = x
		local action = y
		local args = {...}
		
		network.event():FireClient(target, action, unpack(args))
	end
end

network.sendToAll = function(x, ...)
	network.event():FireAllClients(x, ...)
end

network.on = function(action, f)
	table.insert(network.binds, {action, f})
end
network.onFunction = function(action, f)
	table.insert(network.funcBinds, {action, f})
end

if network.isClient then
	network.event().OnClientEvent:connect(function(action, ...)
		for i,v in next, network.binds do
			if v[1] == action then
				v[2](...)
			end
		end
	end)
	
	network.func().OnClientInvoke = function(action, ...)
		for i,v in next, network.funcBinds do
			if v[1] == action then
				return v[2](...)
			end
		end
	end
elseif network.isServer then
	network.event().OnServerEvent:connect(function(player, action, ...)
		for i,v in next, network.binds do
			if v[1] == action then
				v[2](player, ...)
			end
		end
	end)
	
	network.func().OnServerInvoke = function(player, action, ...)
		for i,v in next, network.funcBinds do
			if v[1] == action then
				return v[2](player, ...)
			end
		end
	end
end

return network
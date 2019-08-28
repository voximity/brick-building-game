local kb = {}

kb.binds = {}
kb.bind = function(key, onPress, onRelease)
	table.insert(kb.binds, {key, onPress, onRelease or function() end})
end

local input = game:GetService("UserInputService")

input.InputBegan:connect(function(io)
	if input:GetFocusedTextBox() ~= nil then return end
	for i,v in next, kb.binds do
		if tostring(io.KeyCode):lower():sub(14) == v[1]:lower() then
			v[2]()
		end
	end
end)

input.InputEnded:connect(function(io)
	if input:GetFocusedTextBox() ~= nil then return end
	for i,v in next, kb.binds do
		if tostring(io.KeyCode):lower():sub(14) == v[1]:lower() then
			v[3]()
		end
	end
end)

return kb
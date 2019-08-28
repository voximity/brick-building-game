local service = game:GetService("ContentProvider")

local c = {}

c.load = function(i)
	service:PreloadAsync({i})
end
c.loadFolder = function(f)
	service:PreloadAsync(f:GetChildren())
end
c.loadDirectory = function(d)
	for i,v in next, d:GetChildren() do
		service:PreloadAsync({v})
		c.loadDirectory(v)
	end
end
c.loadMany = function(...)
	service:PreloadAsync({...})
end

local loaded = false
spawn(function()
	c.loadDirectory(game:GetService("ReplicatedStorage").Assets)
	loaded = true
end)

local t = time()
repeat
	wait()
until loaded or time() > t + 5

return c
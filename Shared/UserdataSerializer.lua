local usd = {}

usd.vector3 = function(source)
	local x, y, z = source:match("^%(([-%d.]+),([-%d.]+),([-%d.]+)%)$")
	return Vector3.new(tonumber(x), tonumber(y), tonumber(z))
end

usd.color3 = function(source)
	local x, y, z = source:match("^%(([%d.]+),([%d.]+),([%d.]+)%)$")
	return Color3.new(tonumber(x), tonumber(y), tonumber(z))
end

usd.brickcolor = function(source)
	return BrickColor.new(source)
end

return usd
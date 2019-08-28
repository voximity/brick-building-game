function startsWith(s, x)
	return s:sub(1, #x) == x
end

function split(s, x)
	local t = {}
	for y in s:gmatch("([^" .. x .. "]+)") do
		table.insert(t, y)
	end
	return t
end

return function(me)
	return function(path)
		local place
		local places
		
		if startsWith(path, "./")  then
			places = split(path:sub(3), "/")
			place = me
		elseif startsWith(path, "/") then
			places = split(path:sub(2), "/")
			place = game:GetService("ReplicatedStorage")
		elseif startsWith(path, "../") then
			places = split(path:sub(4), "/")
			place = me.Parent
		else
			error("Invalid path format: " .. path)
		end
		
		for i,v in next, places do
			if v == ".." then
				place = place.Parent
			else
				place = place:FindFirstChild(v)
			end
			
			if place == nil then
				error("No path directory/module in : " .. v)
			end
		end
		
		if not place:IsA("ModuleScript") then
			error("Destination " .. place.Name .. " is not a module")
		end
		
		return require(place)
	end
end
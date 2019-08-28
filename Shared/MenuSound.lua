local ms = {}
ms.clicks = {}
ms.hovers = {}
ms.hits = {}

ms.lastClick = nil
ms.lastHover = nil
ms.lastHit = nil

for i,v in next, game:GetService("ReplicatedStorage").Assets.Sounds.Menu:GetChildren() do
	if v.Name:sub(1, 5) == "Click" then
		table.insert(ms.clicks, v)
	elseif v.Name:sub(1, 5) == "Hover" then
		table.insert(ms.hovers, v)
	elseif v.Name:sub(1, 3) == "Hit" then
		table.insert(ms.hits, v)
	end
end

math.randomseed(os.time())

-- this is a really disgusting implementation of playing sounds without repetition
-- could have made this a single function lul
ms.click = function()
	local l = ms.lastClick
	repeat
		ms.lastClick = ms.clicks[math.random(#ms.clicks)]
	until ms.lastClick ~= l
	return ms.lastClick
end
ms.hover = function()
	local h = ms.lastHover
	repeat
		ms.lastHover = ms.hovers[math.random(#ms.hovers)]
	until ms.lastHover ~= h
	return ms.lastHover
end
ms.hit = function()
	local h = ms.lastHit
	repeat
		ms.lastHit = ms.hits[math.random(#ms.hits)]
	until ms.lastHit ~= h
	return ms.lastHit
end

ms.play = function(s, p)
	local x = s:Clone()
	x.PlayOnRemove = true
	x.Parent = p or workspace.CurrentCamera
	x:Destroy()
end

return ms
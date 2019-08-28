local colors = {}

colors.color = function(bc, trans, material, c3)
	local bc = type(bc) == "string" and BrickColor.new(bc) or bc
	return {
		brickColor = bc,
		color3 = c3 or bc.Color,
		trans = trans or 0,
		material = material or Enum.Material.SmoothPlastic
	}
end
local c = colors.color

colors.list = {
	{"Brights", {
		c "Bright red",
		c "Bright orange",
		c "Bright yellow",
		c "Bright green",
		c "Bright blue",
		c "Dark indigo",
		c "Bright violet"
	}},
	{"Darks", {
		c "Dark red",
		c "Dark orange",
		c "Sand yellow",
		c "Dark green",
		c "Storm blue",
		c "Medium lilac",
		c "Lilac"
	}},
	{"Vivids", {
		c "Really red",
		c "Deep orange",
		c "New Yeller",
		c "Lime green",
		c "Really blue",
		c "Magenta",
		c "Hot pink"
	}},
	--[[{"Earthy", {
		c "Tr. Green",
		c "Earth yellow",
		c "Earth green",
		c "Red flip/flop",
		c "Reddish brown",
		c "Gun metallic",
		c "Pine Cone"
	}},]]
	{"Browns", {
		c "Hurricane grey",
		c "Beige",
		c "Bronze",
		c "Brown",
		c "Rust",
		c "Reddish brown",
		c "Dark nougat"
	}},
	{"Urban", {
		c "Black",
		c "Black metallic",
		c "Light grey metallic",
		c "Silver",
		c "Seashell",
		c "Rust",
		c "Smoky grey"
	}},
	{"Glass", {
		c("Bright red", 0.5, "Glass"),
		c("Bright orange", 0.5, "Glass"),
		c("Bright yellow", 0.5, "Glass"),
		c("Bright green", 0.5, "Glass"),
		c("Bright blue", 0.5, "Glass"),
		c("Dark indigo", 0.5, "Glass"),
		c("Bright violet", 0.5, "Glass")
	}},
	{"Grays", {
		c "Institutional white",
		c "Lily white",
		c "Mid gray",
		c "Light grey",
		c "Cloudy grey",
		c "Flint",
		c "Really black"
	}}
}

return colors
ctf_cosmetics = {}

function ctf_cosmetics.get_colored_skin(player, color)
	return string.format(
		"character.png^(%s^[multiply:%s)^(%s^[multiply:%s)",
		ctf_cosmetics.get_clothing_texture(player, "shirt"),
		color,
		ctf_cosmetics.get_clothing_texture(player, "pants"),
		color
	)
end

function ctf_cosmetics.get_clothing_texture(player, clothing)
	local texture = PlayerObj(player):get_meta():get_string("ctf_cosmetics_"..clothing)

	if not texture or texture == "" then
		return "ctf_cosmetics_"..clothing..".png"
	else
		return texture
	end
end

ctf_modebase.register_mode("classic", {
	map_whitelist = {"bridge", "caverns", "coast", "iceage", "two_hills", "plains"},
	init_player = function(player, teamname)
		player:set_properties({
			textures = {"character.png^(ctf_mode_classic_shirt.png^[colorize:"..ctf_teams.team[teamname].color..":180)"}
		})
	end,
})

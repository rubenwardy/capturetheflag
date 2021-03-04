ctf_modebase = {}

ctf_core.include_files({
	"flags.lua",
	"map_placement.lua",
})

ctf_gui.init()

if ctf_core.settings.server_mode == "play" then
	local match_started = false

	minetest.register_on_joinplayer(function(player)
		if not match_started then
			match_started = true
			ctf_modebase.place_map()
		end
	end)
end

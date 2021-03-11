ctf_modebase = {
	VOTING_TIME = 30,
	modes = {},
	modelist = {},
}

ctf_gui.init()

ctf_core.include_files({
	"flags.lua",
	"functions.lua",
})

if ctf_core.settings.server_mode == "play" then
	local match_started = false

	minetest.register_on_joinplayer(function(player)
		if not match_started then
			ctf_modebase.start_new_match(true)
			match_started = true
		end
	end)
end

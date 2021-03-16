minetest.register_privilege("ctf_admin", {
	description = "Manage administrative ctf settings.",
})

minetest.register_chatcommand("ctf_next", {
	description = "Skip to a new match.",
	privs = {ctf_admin = true},

	func = function()
		ctf_modebase.place_map(ctf_modebase.current_mode)
	end,
})

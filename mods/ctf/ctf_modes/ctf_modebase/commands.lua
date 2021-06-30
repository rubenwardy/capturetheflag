local mode_chatcommands = {}
function ctf_modebase.register_chatcommand(modename, name, def)
	if not mode_chatcommands[modename] then
		mode_chatcommands[modename] = {}
	end

	mode_chatcommands[modename][name] = def.func

	def.func = function(...)
		local current_mode = ctf_modebase.current_mode

		if current_mode then
			local cmd_func = mode_chatcommands[current_mode][name]

			if cmd_func then
				return cmd_func(...)
			else
				return false, "The current mode hasn't implemented that command!"
			end
		else
			return false, "Can't run mode-specific commands when no mode is running!"
		end
	end

	minetest.register_chatcommand(name, def)
end

minetest.register_chatcommand("ctf_next", {
	description = "Skip to a new match.",
	privs = {ctf_admin = true},
	func = function(name, param)
		if param and ctf_modebase.modes[param] then
			ctf_modebase.current_mode = param
			ctf_modebase.start_new_match(nil, true)
			return true
		end

		if ctf_modebase.current_mode then
			ctf_modebase.start_new_match()
			return true
		else
			return false, "You need to provide a mode to go to when running this command at server start"
		end
	end,
})

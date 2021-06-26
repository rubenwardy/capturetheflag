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

local mode_chatcommands = {}
function ctf_modebase.register_chatcommand(modename, name, def)
	if not mode_chatcommands[modename] then
		mode_chatcommands[modename] = {}
	end

	mode_chatcommands[modename][name] = def
end

local function no_such_command(cmd)
	return false, string.format("/m %s: No such command!", cmd)
end

minetest.register_chatcommand("m", {
	description = "Run mode-related commands",
	params = "{[help | h <mode command>] | [list | ls] | [mode command]} [mode command params]",
	privs = {interact = true},
	func = function(name, param)
		local current_mode = ctf_modebase.current_mode

		if not current_mode then
			return false, "There is no mode currently running!"
		end

		if not param or param == "" then
			return false
		end

		param = param:split(" ", false, 1)

		if param[1] == "help" or param[1] == "h" then
			if not param[2] then return false end

			local cmd = mode_chatcommands[current_mode][param[2]]

			if cmd then
				return true, string.format("/m %s %s: %s", param[2], cmd.params or "[]", cmd.description)
			else
				return no_such_command(param[2])
			end
		elseif param[1] == "list" or param[1] == "ls" then
			local out = ""

			for cname, def in pairs(mode_chatcommands[current_mode]) do
				out = string.format("%s\t/m %s %s\n", out, cname, def.params or "")
			end

			return true, string.format("Avaliable mode commands:\n%s", out:sub(1, -2))
		end

		local def = mode_chatcommands[current_mode][param[1]]

		if not def then
			return no_such_command(param[1])
		end

		local can_run, missing_privs = minetest.check_player_privs(name, def.privs)

		if can_run then
			return def.func(name, param[2])
		else
			return false, string.format("You can't run that command! Missing privs: %s", table.concat(missing_privs, ", "))
		end
	end
})

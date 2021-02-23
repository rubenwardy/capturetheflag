if not ctf_core.settings.server_mode or ctf_core.settings.server_mode == "play" then
	assert(
		minetest.get_mapgen_setting("mg_name") == "singlenode",
		"You must use singlenode mapgen when ctf_server_mode is set to 'play'"
	)
end

minetest.register_alias("mapgen_singlenode", "ctf_map:ignore")

ctf_map = {
	DEFAULT_CHEST_AMOUNT = 23,
	DEFAULT_START_TIME = "6:00",
	CHAT_COLOR = "orange",
	maps_dir = minetest.get_modpath("ctf_map").."/maps/",
}

minetest.register_privilege("mapeditor", {
	description = "Allows use of map editing features",
	give_to_singleplayer = false,
	give_to_admin = false,
})

local registered_commands = {}
function ctf_map.register_map_command(match, func)
	registered_commands[match] = func
end

ctf_core.include_files({
	"emerge.lua",
	"nodes.lua",
	"map_meta.lua",
	"map_functions.lua",
	"mapedit_gui.lua",
})

minetest.register_chatcommand("ctf_map", {
	description = "Run map related commands",
	privs = {mapeditor = true},
	params = "[editor | e]",
	func = function(name, params)
		params = string.split(params, " ")

		if params[1] == "e" or params[1] == "editor" then
			ctf_map.show_map_editor(name)

			return true
		end

		for match, func in pairs(registered_commands) do
			if params[1]:match(match) then
				table.remove(params, 1)
				return func(name, params)
			end
		end

		return false
	end
})

-- Attempt to restore user's time speed after server close
local TIME_SPEED = minetest.settings:get("time_speed")

minetest.register_on_shutdown(function()
	minetest.settings:set("time_speed", TIME_SPEED)
end)

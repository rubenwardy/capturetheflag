local choices = {}
local voting = false

function ctf_modebase.start_new_match(show_form)
	local old_map = ctf_map.current_map
	local old_mode = ctf_modebase.current_mode

	give_initial_stuff.reset_stuff_providers()

	local function start_new_match()
		local map = ctf_modebase.place_map(ctf_modebase.current_mode)

		RunCallbacks(ctf_modebase.registered_on_new_match, map, old_map)

		ctf_teams.allocate_teams(map.teams)

		ctf_modebase.current_mode_matches = ctf_modebase.current_mode_matches + 1
	end

	-- Show mode selection form every 'ctf_modebase.MAPS_PER_MODE'-th match
	if ctf_modebase.current_mode_matches >= ctf_modebase.MAPS_PER_MODE or show_form then
		ctf_modebase.current_mode_matches = 0

		choices = {}
		voting = true

		for _, player in pairs(minetest.get_connected_players()) do
			local pname = player:get_player_name()

			local formname = ctf_modebase.show_modechoose_form(player)

			minetest.after(ctf_modebase.VOTING_TIME, minetest.close_formspec, pname, formname)
		end

		minetest.after(ctf_modebase.VOTING_TIME, function()
			local mode_votes = {}
			local most = {c = 0}
			for pname, mode in pairs(choices) do
				mode_votes[mode] = (mode_votes[mode] or 0) + 1

				if mode_votes[mode] > most.c then
					most.n = mode
					most.c = mode_votes[mode]
				end
			end

			if not most.n then
				most.n = ctf_modebase.modelist[math.random(1, #ctf_modebase.modelist)]
			end

			ctf_modebase.current_mode = most.n

			choices = {}
			voting = false

			start_new_match()
				
			RunCallbacks(ctf_modebase.registered_on_new_mode, most.n, old_mode)
		end)
	else
		start_new_match()
	end
end

function ctf_modebase.show_modechoose_form(player)
	local elements = {}
	local idx = 0

	for modename, def in pairs(ctf_modebase.modes) do
		elements[modename] = {
			type = "button",
			label = HumanReadable(modename),
			exit = true,
			pos = {"center", idx},
			func = function(playername, fields, field_name)
				if voting then
					choices[playername] = modename
				end
			end,
		}

		idx = idx + 1
	end

	ctf_gui.show_formspec(player, "ctf_modebase:mode_select", {
		title = "Mode Selection",
		description = "Please vote on what gamemode you would like to play",
		elements = elements,
	})

	return "ctf_modebase:mode_select"
end

--- @param mode_def table | string
function ctf_modebase.place_map(mode_def, mapidx)
	-- Convert name of mode into it's def
	if type(mode_def) == "string" then
		mode_def = ctf_modebase.modes[mode_def]
	end

	local dirlist = minetest.get_dir_list(ctf_map.maps_dir, true)

	if not mapidx then
		if mode_def.map_whitelist then
			mapidx = table.indexof(dirlist, mode_def.map_whitelist[math.random(1, #mode_def.map_whitelist)])
		else
			mapidx = math.random(1, #dirlist)
		end
	elseif type(mapidx) ~= "number" then
		mapidx = table.indexof(dirlist, mapidx)
	end

	local map = ctf_map.place_map(mapidx, dirlist[mapidx])

	-- Set time, time_speed, skyboxes, and physics

	minetest.set_timeofday(map.start_time/24000)

	for _, player in pairs(minetest.get_connected_players()) do
		local name = PlayerName(player)
		local pinv = player:get_inventory()

		if map.initial_stuff ~= nil then
			for _, item in pairs(map.initial_stuff) do
				pinv:add_item("main", ItemStack(item))
			end
		end

		skybox.set(player, table.indexof(ctf_map.skyboxes, map.skybox)-1)

		physics.set(name, "ctf_modebase:map_physics", {
			speed = map.phys_speed,
			jump = map.phys_jump,
			gravity = map.phys_gravity,
		})

		if mode_def.physics then
			player:set_physics_override({
				sneak_glitch = mode_def.physics.sneak_glitch or false,
				new_move = mode_def.physics.new_move or true
			})
		end

		minetest.settings:set("time_speed", map.time_speed * 72)
	end

	ctf_map.announce_map(map)

	return map
end

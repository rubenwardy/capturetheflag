ctf_gui.init()

local choices = {}
function ctf_modebase.start_new_match(show_form)
	if show_form then
		for _, player in pairs(minetest.get_connected_players()) do
			ctf_modebase.show_modechoose_form(player)
		end
	end

	minetest.after(ctf_modebase.VOTING_TIME, function()
		local mode_votes = {}
		local most = {c = 0}
		for _, mode in pairs(choices) do
			mode_votes[mode] = (mode_votes[mode] or 0) + 1

			if mode_votes[mode] > most.c then
				most.n = mode
				most.c = mode_votes[mode]
			end
		end

		if not most.n then
			most.n = ctf_modebase.modelist[math.random(1, #ctf_modebase.modelist)]
		end

		local mode_def = ctf_modebase.modes[most.n]

		if mode_def.map_whitelist then
			local map = ctf_modebase.place_map(mode_def.map_whitelist[math.random(1, #mode_def.map_whitelist)])

			ctf_teams.allocate_teams(map.teams)
		end

		choices = {}
	end)
end

function ctf_modebase.show_modechoose_form(player)
	local elements = {}
	local idx = 0

	for modename, def in pairs(ctf_modebase.modes) do
		elements[modename] = {
			type = "button",
			label = HumanReadable(modename),
			exit = true,
			pos = {((ctf_gui.FORM_SIZE[1] - ctf_gui.ELEM_SIZE[1]) - ctf_gui.SCROLLBAR_WIDTH)/2, idx},
			func = function(playername, fields, field_name)
				choices[playername] = modename
			end,
		}

		idx = idx + 1
	end

	ctf_gui.show_formspec(player, "ctf_modebase:mode_select", {
		title = "Mode Selection",
		description = "Please vote on what gamemode you would like to play",
		elements = elements,
	})
end

function ctf_modebase.place_map(mapidx)
	local dirlist = minetest.get_dir_list(ctf_map.maps_dir, true)

	if not mapidx then
		mapidx = math.random(1, #dirlist)
	elseif type(mapidx) ~= "number" then
		mapidx = table.indexof(dirlist, mapidx)
	end

	local map = ctf_map.place_map(mapidx, dirlist[mapidx])

	ctf_map.announce_map(map)

	return map
end

function ctf_modebase.register_mode(name, def)
	ctf_modebase.modes[name] = def
	table.insert(ctf_modebase.modelist, name)
end

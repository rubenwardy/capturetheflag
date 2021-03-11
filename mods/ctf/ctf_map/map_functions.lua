function ctf_map.announce_map(map)
	local msg = (minetest.colorize("#fcdb05", "Map: ") .. minetest.colorize("#f49200", map.name) ..
	minetest.colorize("#fcdb05", " by ") .. minetest.colorize("#f49200", map.author))
	if map.hint then
		msg = msg .. "\n" .. minetest.colorize("#f49200", map.hint)
	end
	minetest.chat_send_all(msg)
	if minetest.global_exists("irc") and irc.connected then
		irc:say("Map: " .. map.name)
	end
end

function ctf_map.place_map(idx, dirname, mapmeta)
	if not mapmeta then
		mapmeta = ctf_map.load_map_meta(idx, dirname)
	end

	local schempath = ctf_map.maps_dir .. dirname .. "/map.mts"
	local res = minetest.place_schematic(mapmeta.pos1, schempath)

	if tonumber(mapmeta.map_version or "0") < 2 then
		minetest.chat_send_all(minetest.colorize("red", "Not placing flags because map version is < 2 " ..
				"and maps that old may mess up placement"))
	else
		for name, def in pairs(mapmeta.teams) do
			local p = def.flag_pos

			minetest.set_node(p, {name = "ctf_modebase:flag"})
			p = vector.offset(p, 0, 1, 0)
			minetest.set_node(p, {name = "ctf_modebase:flag_top_"..name})
		end
	end

	assert(res, "Unable to place schematic, does the MTS file exist? Path: " .. schempath)

	return mapmeta
end

local getpos_players = {}
function ctf_map.get_pos_from_player(name, amount, donefunc)
	getpos_players[name] = {amount = amount, func = donefunc, positions = {}}

	minetest.chat_send_player(name, "Please punch a node or run /ctf_map thispos to supply coordinates")
end

local function add_position(player, pos)
	pos = vector.round(pos)

	table.insert(getpos_players[player].positions, pos)
	minetest.chat_send_player(player, "Got pos "..minetest.pos_to_string(pos, 1))

	if getpos_players[player].amount > 1 then
		getpos_players[player].amount = getpos_players[player].amount - 1
	else
		minetest.chat_send_player(player, "Done getting positions!")
		getpos_players[player].func(player, getpos_players[player].positions)
		getpos_players[player] = nil
	end
end

ctf_map.register_map_command("thispos", function(name, params)
	local player = PlayerObj(name)

	if player then
		if getpos_players[name] then
			add_position(name, player:get_pos())
			return true
		else
			return false, "You aren't doing anything that requires coordinates"
		end
	end
end)

minetest.register_on_punchnode(function(pos, _, puncher)
	puncher = PlayerName(puncher)

	if getpos_players[puncher] then
		add_position(puncher, pos)
	end
end)

minetest.register_on_leaveplayer(function(player)
	getpos_players[PlayerName(player)] = nil
end)

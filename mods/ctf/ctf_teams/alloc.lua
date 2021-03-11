---@param teams table
function ctf_teams.allocate_teams(teams)
	local players = minetest.get_connected_players()
	local team_list = {}
	local tpos = 1

	for teamname, def in pairs(teams) do
		table.insert(team_list, teamname)
	end

	table.shuffle(players)
	for _, player in ipairs(players) do
		ctf_teams.set_team(player, team_list[tpos])

		player:set_pos(vector.add(
			teams[team_list[tpos]].flag_pos,
			vector.new(math.random(-2, 2), 0.2, math.random(-2, 2))
		))

		if tpos >= #team_list then
			tpos = 1
		else
			tpos = tpos + 1
		end
	end
end

---@param teamname string
function ctf_teams.set_team(player, teamname)
	assert(type(teamname) == "string")
	player = PlayerName(player)

	if not ctf_teams.players[player] or not ctf_teams.players[player].locked then
		ctf_teams.players[player] = {name = teamname}
	end
end

minetest.register_on_leaveplayer(function(player)
	ctf_teams.players[PlayerName(player)] = nil
end)

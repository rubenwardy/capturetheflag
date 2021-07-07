ChatCmdBuilder.new("ctf_teams", function(cmd)
	cmd:sub("set :player :team", function(name, player, team)
		if minetest.get_player_by_name(player) then
			if not ctf_teams.team[team] then
				return false, "Unable to find team " .. dump(team)
			end

			ctf_teams.set_team(player, team)

			return true, string.format("Allocated %s to team %s", player, team)
		else
			return false, "Unable to find player " .. dump(player)
		end
	end)

	cmd:sub("rset :pattern :team", function(name, pattern, team)
		local added = {}

		for _, player in pairs(minetest.get_connected_players()) do
			local pname = player:get_player_name()

			if pname:match(pattern) then
				if ctf_teams.set_team(player, team) then
					table.insert(added, pname)
				end
			end
		end

		if #added >= 1 then
			return true, "Added the following players to team "..team..": "..table.concat(added, ", ")
		else
			return false, "No player names matched the given regex, or all players that matched were locked to a team"
		end
	end)
end, {
	description = "\n" ..
			"set <player> <team>",
			"rset <match pattern> <team>",
	privs = {
		ctf_team_admin = true,
	}
})
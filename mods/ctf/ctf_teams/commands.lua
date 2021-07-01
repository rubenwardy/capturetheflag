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
end, {
	description = "\n" ..
			"set <player> <team>",
	privs = {
		ctf_team_admin = true,
	}
})

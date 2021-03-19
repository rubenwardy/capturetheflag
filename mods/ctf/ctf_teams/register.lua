ctf_teams.registered_on_allocplayer = {}
function ctf_teams.register_on_allocplayer(func)
	table.insert(ctf_teams.registered_on_allocplayer, func)
end

ctf_teams = {
	team = {
		red = {
			color = "#dd0000"
		},
		green = {
			color = "#00bb00",
		},
		blue = {
			color = "#0073ff",
		},
		orange = {
			color = "#ff7700",
		},
		purple = {
			color = "#6f00a7"
		},
	},
	teamlist = {},
	players = {},
}

for team in pairs(ctf_teams.team) do
	table.insert(ctf_teams.teamlist, team)
end

ctf_core.include_files({"alloc.lua"})

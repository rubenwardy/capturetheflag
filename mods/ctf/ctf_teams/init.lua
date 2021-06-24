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
			color = "#6f00a7",
		},
	},
	teamlist = {},
	player_team = {},
}

for team, def in pairs(ctf_teams.team) do
	table.insert(ctf_teams.teamlist, team)

	ctf_teams.team[team].color_hex = tonumber("0x"..def.color:sub(2))
end

minetest.register_privilege("ctf_team_admin", {
	description = "Allows advanced team management.",
	give_to_singleplayer = false,
	give_to_admin = false,
})

ctf_core.include_files(
	"functions.lua",
	"commands.lua",
	"register.lua",
	"nodes.lua"
)

minetest.register_on_joinplayer(function(player)
	ctf_teams.allocate_player(player)
end)

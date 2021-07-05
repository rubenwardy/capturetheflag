ctf_teams = {
	team = {
		red = {
			color = "#dd0000",
			color_hex = 0x000,
		},
		green = {
			color = "#00bb00",
			color_hex = 0x000,
		},
		blue = {
			color = "#0073ff",
			color_hex = 0x000,
		},
		orange = {
			color = "#ff7700",
			color_hex = 0x000,
		},
		purple = {
			color = "#6f00a7",
			color_hex = 0x000,
		},
	},
	teamlist = {},
	player_team = {},
	current_team_list = {},
	remembered_player = {}, -- Holds players that have been set to a team previously. Format: ["player_name"] = teamname

	team_chests = {}, -- Whenever a team chest is initialized it'll be put in this table
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
	"team_chest.lua",
	"team_door.lua"
)

minetest.register_on_joinplayer(function(player)
	ctf_teams.allocate_player(player)
end)

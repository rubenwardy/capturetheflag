unused_args = false

globals = {
	"ctf_core", "ctf_map", "ctf_teams", "ctf_modebase", "ctf_gui",
	"ctf_rankings",

	"mode_classic",

	"PlayerObj", "PlayerName", "HumanReadable", "RunCallbacks",

	"ChatCmdBuilder", "mhud",

	"physics", "give_initial_stuff", "medkits", "grenades", "dropondie",
	"vote", "random_messages", "sfinv", "email", "hb", "wield3d", "irc",
	"default", "skybox", "crafting",

	"vector",
	math = {
		fields = {
			"round",
			"hypot",
			"sign",
			"factorial",
			"ceil",
		}
	},
}

exclude_files = {
	"mods/other/crafting",
	"mods/mtg/mtg_*"
}

read_globals = {
	"DIR_DELIM",
	"minetest", "core",
	"dump", "dump2",
	"VoxelManip", "VoxelArea",
	"PseudoRandom", "PcgRandom",
	"ItemStack",
	"Settings",
	"unpack",

	table = {
		fields = {
			"copy",
			"indexof",
			"insert_all",
			"key_value_swap",
			"shuffle",
		}
	},

	string = {
		fields = {
			"split",
			"trim",
		}
	},
}

local flag_huds, rankings, build_timer = ctf_core.include_files(
	"flag_huds.lua",
	"rankings.lua",
	"build_timer.lua"
)

local function tp_player_near_flag(player)
	local pname = PlayerName(player)

	if not ctf_teams.player_team[pname] then
		return
	end

	local tname = ctf_teams.player_team[pname].name

	player:set_pos(
		vector.offset(ctf_map.current_map.teams[tname].flag_pos,
			math.random(-2, 2),
			0.5,
			math.random(-2, 2)
		)
	)

	return true
end

local function celebrate_team(teamname)
	for _, player in pairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		local pteam = ctf_teams.player_team[pname].name

		if pteam == teamname then
			minetest.sound_play("ctf_modebase_trumpet_positive", {
				to_player = pname,
				gain = 1.0,
				pitch = 1.0,
			}, true)
		else
			minetest.sound_play("ctf_modebase_trumpet_negative", {
				to_player = pname,
				gain = 1.0,
				pitch = 1.0,
			}, true)
		end
	end
end

ctf_modebase.register_mode("classic", {
	map_whitelist = {--[[ "bridge", "caverns", "coast", "iceage", "two_hills",  ]]"plains"},
	treasures = {
		["default:ladder"] = {max_count = 20, rarity = 0.3, max_stacks = 5},
		["default:torch"] = {max_count = 20, rarity = 0.3, max_stacks = 5},
		["default:cobble"] = {min_count = 45, max_count = 99, rarity = 0.4, max_stacks = 5},
		["default:wood"] = {min_count = 10, max_count = 60, rarity = 0.5, max_stacks = 4},

		["default:pick_steel"] = {max_count = 1, rarity = 0.5, max_stacks = 3},
		["default:shovel_steel"] = {max_count = 1, rarity = 0.5, max_stacks = 2},
		["default:axe_steel"] = {max_count = 1, rarity = 0.5, max_stacks = 2},

		["default:apple"] = {min_count = 5, max_count = 30, rarity = 0.1, max_stacks = 3},
	},
	physics = {sneak_glitch = true, new_move = false},
	on_allocplayer = function(player, teamname)
		player:set_properties({
			textures = {"character.png^(ctf_mode_classic_shirt.png^[colorize:"..ctf_teams.team[teamname].color..":180)"}
		})

		tp_player_near_flag(player)

		flag_huds.on_allocplayer(player)
	end,
	on_dieplayer = function(player, reason)
		if reason.type == "punch" and reason.object:is_player() then
			rankings.give(reason.object, {kills = 1, score = rankings.calculate_killscore(player)})
			rankings.give(player, {deaths = 1})
		end
	end,
	on_respawnplayer = tp_player_near_flag,
	on_flag_take = function(player, teamname)
		if build_timer.in_progress() then
			tp_player_near_flag(player)

			return "You can't take the enemy flag during build time!"
		end

		celebrate_team(ctf_teams.get_team(player))

		rankings.give(player, {score = 20})

		flag_huds.update()
	end,
	on_flag_drop = function(player, teamname)
		flag_huds.update()
	end,
	on_flag_capture = function(player, captured_team)
		celebrate_team(ctf_teams.get_team(player))

		flag_huds.update()

		rankings.give(player, {score = 30})

		minetest.after(3, ctf_modebase.start_new_match)
	end,
	on_new_match = function(mapdef)
		rankings.reset_recent()

		build_timer.start(mapdef)

		ctf_map.place_chests(mapdef)
	end,
})

mode_classic = {}

local flag_huds, rankings, build_timer, crafts = ctf_core.include_files(
	"flag_huds.lua",
	"rankings.lua",
	"build_timer.lua",
	"crafts.lua"
)

local function summary_func(name)
	return name, rankings.get_recent(), {"flag_captures", "flag_attempts", _sort = "score", "kills", "deaths"}
end

function mode_classic.tp_player_near_flag(player)
	local tname = ctf_teams.get(player)

	if not tname then return end

	PlayerObj(player):set_pos(
		vector.offset(ctf_map.current_map.teams[tname].flag_pos,
			math.random(-2, 2),
			0.5,
			math.random(-2, 2)
		)
	)

	return true
end

function mode_classic.celebrate_team(teamname)
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
	map_whitelist = {--[[ "bridge", "caverns", "coast", "iceage", "two_hills", ]] "plains"},
	treasures = {
		["default:ladder_wood"] = {                max_count = 20, rarity = 0.3, max_stacks = 5},
		["default:torch" ] = {                max_count = 20, rarity = 0.3, max_stacks = 5},
		["default:cobble"] = {min_count = 45, max_count = 99, rarity = 0.4, max_stacks = 5},
		["default:wood"  ] = {min_count = 10, max_count = 60, rarity = 0.5, max_stacks = 4},

		["default:pick_steel"  ] = {rarity = 0.4, max_stacks = 3},
		["default:shovel_steel"] = {rarity = 0.4, max_stacks = 2},
		["default:axe_steel"   ] = {rarity = 0.4, max_stacks = 2},

		["ctf_melee:sword_steel"  ] = {rarity = 0.2  , max_stacks = 2},
		["ctf_melee:sword_mese"   ] = {rarity = 0.05 , max_stacks = 1},
		["ctf_melee:sword_diamond"] = {rarity = 0.002, max_stacks = 1},

		["ctf_ranged:pistol_loaded" ] = {rarity = 0.2 , max_stacks = 2},
		["ctf_ranged:rifle_loaded"  ] = {rarity = 0.2                 },
		["ctf_ranged:shotgun_loaded"] = {rarity = 0.05                },
		["ctf_ranged:smg_loaded"    ] = {rarity = 0.05                },

		["ctf_ranged:ammo"] = {min_count = 3, max_count = 10, rarity = 0.3, max_stacks = 2},
		["default:apple"  ] = {min_count = 5, max_count = 30, rarity = 0.1, max_stacks = 2},
	},
	crafts = crafts,
	physics = {sneak_glitch = true, new_move = false},
	commands = {"ctf_start", "rank", "r"},
	on_new_match = function(mapdef)
		rankings.reset_recent()

		build_timer.start(mapdef)

		give_initial_stuff.register_stuff_provider(function()
			return {"default:sword_stone", "default:pick_stone", "default:torch 15", "default:stick 5"}
		end)

		ctf_map.place_chests(mapdef)
	end,
	on_allocplayer = function(player, teamname)
		player:set_properties({
			textures = {"character.png^(ctf_mode_classic_shirt.png^[colorize:"..ctf_teams.team[teamname].color..":180)"}
		})

		ctf_playertag.set(player, ctf_playertag.TYPE_ENTITY)

		player:set_hp(player:get_properties().hp_max)

		mode_classic.tp_player_near_flag(player)

		give_initial_stuff(player)

		flag_huds.on_allocplayer(player)
	end,
	on_dieplayer = function(player, reason)
		if reason.type == "punch" and reason.object:is_player() then
			rankings.add(reason.object, {kills = 1, score = rankings.calculate_killscore(player)})
		end

		rankings.add(player, {deaths = 1})
	end,
	on_respawnplayer = function(player)
		give_initial_stuff(player)

		return mode_classic.tp_player_near_flag(player)
	end,
	on_flag_take = function(player, teamname)
		if build_timer.in_progress() then
			mode_classic.tp_player_near_flag(player)

			return "You can't take the enemy flag during build time!"
		end

		local pteam = ctf_teams.get(player)
		local tcolor = pteam and ctf_teams.team[pteam].color or "#FFF"
		ctf_playertag.set(minetest.get_player_by_name(player), ctf_playertag.TYPE_BUILTIN, tcolor)

		mode_classic.celebrate_team(ctf_teams.get(player))

		rankings.add(player, {score = 20, flag_attempts = 1})

		flag_huds.update()
	end,
	on_flag_drop = function(player, teamname)
		flag_huds.update()

		ctf_playertag.set(minetest.get_player_by_name(player), ctf_playertag.TYPE_ENTITY)
	end,
	on_flag_capture = function(player, captured_team)
		mode_classic.celebrate_team(ctf_teams.get(player))

		flag_huds.update()

		rankings.add(player, {score = 30, flag_captures = 1})

		for _, pname in pairs(minetest.get_connected_players()) do
			pname = pname:get_player_name()

			ctf_modebase.show_summary_gui(summary_func(pname))
		end

		ctf_playertag.set(minetest.get_player_by_name(player), ctf_playertag.TYPE_ENTITY)

		minetest.after(3, ctf_modebase.start_new_match)
	end,
	get_chest_access = function(pname)
		local rank = rankings.get(pname)

		if not rank then return end

		if rank.score >= 100 then
			return "pro"
		elseif rank.score >= 10 then
			return true
		end
	end,
	summary_func = summary_func,
	on_punchplayer = function(player, hitter)
		local pname, hname = player:get_player_name(), hitter:get_player_name()
		local pteam, hteam = ctf_teams.get(player), ctf_teams.get(hitter)

		if not pteam then
			minetest.chat_send_player(hname, pname .. " is not in a team!")
			return true
		elseif not hteam then
			minetest.chat_send_player(hname, "You are not in a team!")
			return true
		end

		if pteam == hteam then
			minetest.chat_send_player(hname, pname .. " is on your team!")

			return true
		elseif build_timer.in_progress() then
			minetest.chat_send_player(hname, "The match hasn't started yet!")
			return true
		end
	end,
})

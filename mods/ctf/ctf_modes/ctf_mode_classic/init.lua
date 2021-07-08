mode_classic = {
	SUMMARY_RANKS = {"flag_captures", _sort = "score", "flag_attempts", "kills", "deaths", "hp_healed"}
}

local flag_huds, rankings, build_timer, crafts = ctf_core.include_files(
	"flag_huds.lua",
	"rankings.lua",
	"build_timer.lua",
	"crafts.lua"
)

local FLAG_CAPTURE_TIMER = 60 * 2.5

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

local next_team = "red"
ctf_modebase.register_mode("classic", {
	map_whitelist = {"bridge", "caverns", "coast", "iceage", "two_hills", "plains", "desert_spikes"},
	treasures = {
		["default:ladder_wood"] = {                max_count = 20, rarity = 0.3, max_stacks = 5},
		["default:torch" ] = {                max_count = 20, rarity = 0.3, max_stacks = 5},
		["default:cobble"] = {min_count = 45, max_count = 99, rarity = 0.4, max_stacks = 5},
		["default:wood"  ] = {min_count = 10, max_count = 60, rarity = 0.5, max_stacks = 4},

		["ctf_teams:door_steel"] = {rarity = 0.2, max_stacks = 3},

		["default:pick_steel"  ] = {rarity = 0.4, max_stacks = 3},
		["default:shovel_steel"] = {rarity = 0.4, max_stacks = 2},
		["default:axe_steel"   ] = {rarity = 0.4, max_stacks = 2},

		["ctf_melee:sword_steel"  ] = {rarity = 0.2  , max_stacks = 2},
		["ctf_melee:sword_mese"   ] = {rarity = 0.05 , max_stacks = 1},
		["ctf_melee:sword_diamond"] = {rarity = 0.001, max_stacks = 1},

		["ctf_ranged:pistol_loaded" ] = {rarity = 0.2 , max_stacks = 2},
		["ctf_ranged:rifle_loaded"  ] = {rarity = 0.2                 },
		["ctf_ranged:shotgun_loaded"] = {rarity = 0.05                },
		["ctf_ranged:smg_loaded"    ] = {rarity = 0.05                },

		["ctf_ranged:ammo"     ] = {min_count = 3, max_count = 10, rarity = 0.3 , max_stacks = 2},
		["default:apple"       ] = {min_count = 5, max_count = 30, rarity = 0.1 , max_stacks = 2},
		["ctf_healing:bandage" ] = {                               rarity = 0.2 , max_stacks = 1},

		["grenades:frag" ] = {rarity = 0.1, max_stacks = 2},
		["grenades:smoke"] = {rarity = 0.2, max_stacks = 2},
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
	allocate_player = function(player)
		player = player:get_player_name()

		local total = rankings.get_total()
		local bscore = (total.blue and total.blue.score) or 0
		local rscore = (total.red and total.red.score) or 0

		if math.abs(bscore - rscore) <= 100 then
			if not ctf_teams.remembered_player[player] then
				ctf_teams.set_team(player, next_team)
				next_team = next_team == "red" and "blue" or "red"
			else
				ctf_teams.set_team(player, ctf_teams.remembered_player[player])
			end
		elseif bscore > rscore then
			-- Only allocate player to remembered team if they aren't desperately needed in the other
			if ctf_teams.remembered_player[player] and bscore - rscore < 500 then
				ctf_teams.set_team(player, ctf_teams.remembered_player[player])
			else
				ctf_teams.set_team(player, "red")
			end
		else
			-- Only allocate player to remembered team if they aren't desperately needed in the other
			if ctf_teams.remembered_player[player] and rscore - bscore < 500 then
				ctf_teams.set_team(player, ctf_teams.remembered_player[player])
			else
				ctf_teams.set_team(player, "blue")
			end
		end
	end,
	on_allocplayer = function(player, teamname)
		local tcolor = ctf_teams.team[teamname].color

		player:set_properties({
			textures = {"character.png^(ctf_mode_classic_shirt.png^[colorize:"..tcolor..":180)"}
		})

		player:hud_set_hotbar_image("gui_hotbar.png^[colorize:" .. ctf_teams.team[teamname].color .. ":180")
		player:hud_set_hotbar_selected_image("gui_hotbar_selected.png^[colorize:" .. ctf_teams.team[teamname].color .. ":180")

		rankings.set_summary_row_color(player, tcolor)

		ctf_playertag.set(player, ctf_playertag.TYPE_ENTITY)

		player:set_hp(player:get_properties().hp_max)

		mode_classic.tp_player_near_flag(player)

		give_initial_stuff(player)

		flag_huds.on_allocplayer(player)
	end,
	on_leaveplayer = function(player)
		local pname = player:get_player_name()
		local recent = rankings.get_recent(pname)
		local count = 0

		for _ in pairs(recent or {}) do
			count = count + 1
		end

		if not recent or count <= 1 then
			rankings.reset_recent(pname)
		end

		flag_huds.untrack_capturer(pname)
	end,
	on_dieplayer = function(player, reason)
		local killscore = rankings.calculate_killscore(player)

		if reason.type == "punch" and reason.object:is_player() then
			local combat = ctf_combat_mode.get(reason.object)

			rankings.add(reason.object, {kills = 1, score = killscore})

			if combat and combat.extra.healer then
				rankings.add(combat.extra.healer, {score = math.ceil(killscore/2)})
			end
		else
			local combat_mode = ctf_combat_mode.get(player)

			if combat_mode and combat_mode.extra.hitter then
				local hitter_combat = ctf_combat_mode.get(combat_mode.extra.hitter)

				rankings.add(combat_mode.extra.hitter, {kills = 1, score = killscore})

				if hitter_combat and hitter_combat.extra.healer then
					rankings.add(hitter_combat.extra.healer, {score = math.ceil(killscore/2)})
				end

				ctf_kill_list.add_kill(combat_mode.extra.hitter, nil, player)
			else
				ctf_kill_list.add_kill("", "ctf_modebase_skull.png", player)
			end
		end

		ctf_combat_mode.remove(player)

		if not build_timer.in_progress() then
			ctf_modebase.prep_delayed_respawn(player)
		end

		rankings.add(player, {deaths = 1})
	end,
	on_respawnplayer = function(player)
		if not build_timer.in_progress() then
			local waitpos = player:get_pos()

			waitpos.y = ctf_map.current_map.pos2.y + 5

			if ctf_modebase.delay_respawn(player, 7, 4) then
				return true
			end
		end

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

		flag_huds.track_capturer(player, FLAG_CAPTURE_TIMER)
	end,
	on_flag_drop = function(player, teamname)
		flag_huds.update()

		flag_huds.untrack_capturer(player)

		ctf_playertag.set(minetest.get_player_by_name(player), ctf_playertag.TYPE_ENTITY)
	end,
	on_flag_capture = function(player, captured_team)
		mode_classic.celebrate_team(ctf_teams.get(player))

		flag_huds.update()

		flag_huds.clear_capturers()

		rankings.add(player, {score = 30, flag_captures = 1})

		for _, pname in pairs(minetest.get_connected_players()) do
			pname = pname:get_player_name()

			ctf_modebase.show_summary_gui(pname, rankings.get_recent(), mode_classic.SUMMARY_RANKS, {previous = true})
		end

		ctf_playertag.set(minetest.get_player_by_name(player), ctf_playertag.TYPE_ENTITY)

		minetest.after(3, ctf_modebase.start_new_match)
	end,
	get_chest_access = function(pname)
		local rank = rankings.get(pname)

		if not rank or not rank.score then return end

		if rank.score >= 10000 then
			return "pro"
		elseif rank.score >= 10 then
			return true
		end
	end,
	summary_func = function(name, param)
		if not param or param == "" then
			return true, rankings.get_recent() or {}, mode_classic.SUMMARY_RANKS, {previous = true}
		elseif param:match("p") then
			return true, rankings.get_previous_recent() or {}, mode_classic.SUMMARY_RANKS, {next = true}
		else
			return false, "Don't understand param "..dump(param)
		end
	end,
	on_punchplayer = function(player, hitter, ...)
		if not hitter:is_player() or player:get_hp() <= 0 then return end

		local pname, hname = player:get_player_name(), hitter:get_player_name()
		local pteam, hteam = ctf_teams.get(player), ctf_teams.get(hitter)

		if not pteam then
			minetest.chat_send_player(hname, pname .. " is not in a team!")
			return true
		elseif not hteam then
			minetest.chat_send_player(hname, "You are not in a team!")
			return true
		end

		if pteam == hteam and pname ~= hname then
			minetest.chat_send_player(hname, pname .. " is on your team!")

			return true
		elseif build_timer.in_progress() then
			minetest.chat_send_player(hname, "The match hasn't started yet!")
			return true
		end

		ctf_combat_mode.set(player, 15, {hitter = hitter:get_player_name()})

		ctf_kill_list.on_punchplayer(player, hitter, ...)
	end,
	on_healplayer = function(player, patient, amount)
		ctf_combat_mode.set(patient, 15, {healer = player:get_player_name()})

		rankings.add(player, {hp_healed = amount}, true)
	end,
	calculate_knockback = function()
		return 0
	end,
})

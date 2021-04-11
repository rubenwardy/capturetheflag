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

local flag_huds = ctf_core.include_files(
	"flag_huds.lua"
)

ctf_modebase.register_mode("classic", {
	map_whitelist = {"bridge", "caverns", "coast", "iceage", "two_hills", "plains"},
	on_allocplayer = function(player, teamname)
		player:set_properties({
			textures = {"character.png^(ctf_mode_classic_shirt.png^[colorize:"..ctf_teams.team[teamname].color..":180)"}
		})

		tp_player_near_flag(player)

		flag_huds.on_allocplayer(player)
	end,
	on_respawnplayer = tp_player_near_flag,
	on_flag_take = function(player, teamname)
		celebrate_team(ctf_teams.get_team(player))

		flag_huds.update()
	end,
	on_flag_drop = function(player, teamname)
		flag_huds.update()
	end,
	on_flag_capture = function(player, captured_team)
		celebrate_team(ctf_teams.get_team(player))

		flag_huds.update()

		minetest.after(10, ctf_modebase.start_new_match)
	end,
})

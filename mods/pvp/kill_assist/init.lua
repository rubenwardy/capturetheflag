kill_assist = {}

local kill_assists = {}

function kill_assist.clear_assists(player)
	if type(player) == "string" then
		kill_assists[player] = nil
	else
		kill_assists = {}
	end
end

function kill_assist.add_assist(victim, attacker, damage)
	if not kill_assists[victim] then
		kill_assists[victim] = {}
	end

	kill_assists[victim][attacker] = (kill_assists[victim][attacker] or 0) + damage
end

function kill_assist.add_heal_assist(victim, healed_hp)
	if not kill_assists[victim] then return end

	for name, damage in pairs(kill_assists[victim]) do
		kill_assists[victim][name] = math.max(damage - healed_hp, 0)
	end
end

function kill_assist.reward_assists(victim, killer, reward)
	if not kill_assists[victim] then return end

	for name, damage in pairs(kill_assists[victim]) do
		if minetest.get_player_by_name(name) and name ~= victim then
			local standard = 0
			local max_hp = minetest.get_player_by_name(victim):get_properties().max_hp or 20
			local help_percent = damage / max_hp
			local main, match = ctf_stats.player(name)
			local color = "0x00FFFF"

			if name ~= killer then
				standard = 0.5
				help_percent = math.min(help_percent, 0.75)
			else
				help_percent = math.min(help_percent, 1)
			end

			if help_percent >= standard then
				reward = math.floor((reward * help_percent)*100)/100
			end

			if reward < 1 then
				reward = 1
			end

			match.score = match.score + reward
			main.score = main.score + reward

			if name == killer then
				color = "0x00FF00"
				main.kills = main.kills + 1
				match.kills = match.kills + 1
				match.kills_since_death = match.kills_since_death + 1
			end

			hud_score.new(name, {
				name = "kill_assist:score",
				color = color,
				value = reward
			})
		end
	end

	ctf_stats.request_save()
	kill_assist.clear_assists(victim)
end

ctf.register_on_killedplayer(function(victim, killer, _, toolcaps)
	local reward = ctf_stats.calculateKillReward(victim, killer, toolcaps)
	reward = math.floor(reward * 100) / 100
	kill_assist.reward_assists(victim, killer, reward)
end)

ctf.register_on_punchplayer(function(player, hitter, _, _, _, damage)
	kill_assist.add_assist(player:get_player_name(), hitter:get_player_name(), damage)
end)

ctf_match.register_on_new_match(function()
	kill_assist.clear_assists()
end)
ctf.register_on_new_game(function()
	kill_assist.clear_assists()
end)
minetest.register_on_leaveplayer(function(player)
	kill_assist.clear_assists(player)
end)

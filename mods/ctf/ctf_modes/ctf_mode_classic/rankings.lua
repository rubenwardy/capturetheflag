local rankings = ctf_rankings.init()

rankings.total = {}

----
------ COMMANDS
----

local rank_def = {
	description = "Get the rank of yourself or a player",
	params = "[playername]",
	func = function(name, param)
		local target = name

		if param and param ~= "" then
			target = param
		end

		local prank = rankings:get(target) -- [p]layer [rank]

		if not prank then
			return false, string.format("Player %s has no rankings!", target)
		end

		return true, string.format("Rankings of player %s: %s", target, HumanReadable(dump2(prank)))
	end
}

ctf_modebase.register_chatcommand("classic", "rank", rank_def)
ctf_modebase.register_chatcommand("classic", "r"   , rank_def)

return {
	add = function(player, amounts, no_hud)
		local hud_text = ""
		local pteam = ctf_teams.get(player)

		for name, val in pairs(amounts) do
			hud_text = string.format("%s+%d %s | ", hud_text, val, HumanReadable(name))
		end

		if pteam then
			if not rankings.total[pteam] then
				rankings.total[pteam] = {}
			end

			for stat, amount in pairs(amounts) do
				rankings.total[pteam][stat] = (rankings.total[pteam][stat] or 0) + amount
			end
		end

		if not no_hud then
			hud_events.new(player, {text = hud_text:sub(1, -4)})
		end

		rankings:add(player, amounts)
	end,
	set_summary_row_color = function(player, color)
		local pname = PlayerName(player)

		if not rankings.recent[pname] then
			rankings.recent[pname] = {_row_color = color}
		else
			rankings.recent[pname]._row_color = color
		end
	end,
	get = function(player, specific)
		local rank = rankings:get(player)

		return (specific and rank[specific]) or rank
	end,
	calculate_killscore = function(player)
		local match_rank = rankings.recent[PlayerName(player)] or {}
		local kd = (match_rank.kills or 1) / (match_rank.deaths or 1)

		return math.round(kd * 5)
	end,
	reset_recent = function(specific_player)
		if not specific_player then
			rankings.previous_recent = table.copy(rankings.recent)
			rankings.recent = {}
			rankings.total = {}
		else
			rankings.recent[specific_player] = nil
		end
	end,
	get_total = function(specific_team)
		if specific_team then
			return rankings.total[specific_team]
		else
			return rankings.total
		end
	end,
	get_previous_recent = function()
		return rankings.previous_recent or false
	end,
	get_recent = function(specific_player)
		return specific_player and rankings.recent[specific_player] or rankings.recent
	end
}

local rankings = ctf_rankings.init()

-- can't call minetest.get_mod_storage() twice, the modstorage rankings backend calls it first
local mods = rankings.modstorage or minetest.get_mod_storage()

rankings.total = {}
rankings.top_50 = minetest.deserialize(mods:get_string("top_50")) or {}

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

		return true, string.format("Rankings of player %s: %s", target, HumanReadable(dump(prank)))
	end
}

ctf_modebase.register_chatcommand("classic", "rank", rank_def)
ctf_modebase.register_chatcommand("classic", "r"   , rank_def)

ctf_modebase.register_chatcommand("classic", "reset_rankings", {
	description = minetest.colorize("red", "Resets rankings of you or another player to nothing"),
	params = "[playername]",
	func = function(name, param)
		if param and param ~= "" then
			if minetest.check_player_privs(name, {ctf_admin = true}) then
				rankings:set(param, {}, true)

				return true, "Rankings reset for player "..param
			else
				return false, "The ctf_admin priv is required to reset the rankings of other players!"
			end
		else
			rankings:set(name, {}, true)

			return true, "Your rankings have been reset"
		end
	end
})

ctf_modebase.register_chatcommand("classic", "top50", {
	description = "Show the top 50 players",
	func = function(name)
		local top50 = {}

		for _, pname in pairs(rankings.top_50) do
			top50[pname] = rankings:get(pname) or nil
		end

		ctf_modebase.show_summary_gui(name, top50, mode_classic.SUMMARY_RANKS, {
			title = "Top 50 Players",
			disable_nonuser_colors = true
		})
	end,
})

local function update_top_50()
	local cache = {}

	table.sort(rankings.top_50, function(a, b)
		if not cache[a] then cache[a] = rankings:get(a) or {score = 0} end
		if not cache[b] then cache[b] = rankings:get(b) or {score = 0} end

		return (cache[a].score or 0) < (cache[b].score or 0)
	end)

	mods:set_string("top_50", minetest.serialize(rankings.top_50))
end

return {
	add = function(player, amounts, no_hud)
		local hud_text = ""
		local pteam = ctf_teams.get(player)
		player = PlayerName(player)

		for name, val in pairs(amounts) do
			hud_text = string.format("%s+%d %s | ", hud_text, val, HumanReadable(name))
		end

		if amounts.score then -- handle top50
			local current = rankings:get(player)

			if table.indexof(rankings.top_50, player) == -1 then
				if rankings.top_50[50] then
					if current.score or 0 + amounts.score > rankings:get(rankings.top_50[50]).score then
						table.remove(rankings.top_50)
						table.insert(rankings.top_50, player)

						update_top_50()
					end
				else
					table.insert(rankings.top_50, player)
					update_top_50()
				end
			else
				update_top_50()
			end
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

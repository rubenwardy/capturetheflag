local rankings = ctf_rankings.init()
local hud = mhud.init()

local hud_queues = {}

minetest.register_on_leaveplayer(function(player)
	hud:clear(player)
	hud_queues[player] = nil
end)

local function show_stat_hud(player, text)
	local pname = player:get_player_name()

	if not hud:exists(player, "stat_hud") then
		hud:add(player, "stat_hud", {
			hud_elem_type = "text",
			position = {x = 0.5, y = 0.5},
			offset = {x = 0, y = 20},
			alignment = {x = "center", y = "down"},
			text = text,
			color = 0x00D1FF,
		})
	else
		hud:change(player, "stat_hud", {text = ""})

		minetest.after(1, function()
			player = minetest.get_player_by_name(pname)
			if not player then return end

			hud:change(player, "stat_hud", {
				text = text
			})
		end)
	end
end

local function handle_stat_huds(pname)
	local player = minetest.get_player_by_name(pname)
	if not player or not hud_queues[pname] then return end

	show_stat_hud(player, table.remove(hud_queues[pname], 1))

	minetest.after(5, function()
		player = minetest.get_player_by_name(pname)
		if not player or not hud_queues[pname] then return end

		if #hud_queues[pname] >= 1 then
			handle_stat_huds(pname)
		else
			hud:remove(player, "stat_hud")
			hud_queues[pname]._started = false
		end
	end)
end

local function queue_ranking_update(player, text)
	player = PlayerObj(player)
	local pname = player:get_player_name()

	if not hud_queues[pname] then
		hud_queues[pname] = {_started = false}
	end

	table.insert(hud_queues[pname], text)

	if not hud_queues[pname]._started then
		hud_queues[pname]._started = true
		handle_stat_huds(pname)
	end
end

return {
	add = function(player, amounts)
		local hud_text = ""

		for name, val in pairs(amounts) do
			hud_text = string.format("%s+%d %s | ", hud_text, val, HumanReadable(name))
		end

		queue_ranking_update(player, hud_text:sub(1, -4))
		rankings:add(player, amounts)
	end,
	calculate_killscore = function(player)
		local match_rank = rankings.recent[PlayerName(player)] or {}
		local kd = (match_rank.kills or 1) / (match_rank.deaths or 1)

		return math.round(kd * 5)
	end,
	reset_recent = function()
		rankings.recent = {}
	end,
	get_recent = function()
		return rankings.recent
	end
}

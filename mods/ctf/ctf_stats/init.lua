ctf_stats = {}

local storage = minetest.get_mod_storage()
local data_to_persist = { "matches", "players" }

function ctf_stats.load_legacy()
	local file = io.open(minetest.get_worldpath() .. "/ctf_stats.txt", "r")
	if not file then
		return false
	end

	local table = minetest.deserialize(file:read("*all"))
	file:close()
	if type(table) ~= "table" then
		return false
	end

	ctf.log("ctf_stats", "Migrating stats...")
	--ctf_stats.matches = table.matches
	ctf_stats.players = table.players

	for name, player_stats in pairs(ctf_stats.players) do
		if not player_stats.score or player_stats.score < 0 then
			player_stats.score = 0
		end
		if player_stats.score > 300 then
			player_stats.score = (player_stats.score - 300) / 30 + 300
		end
		if player_stats.score > 800 then
			player_stats.score = 800
		end
	end

	ctf.needs_save = true

	os.remove(minetest.get_worldpath() .. "/ctf_stats.txt")
	return true
end

function ctf_stats.load()
	if not ctf_stats.load_legacy() then
		for _, key in pairs(data_to_persist) do
			ctf_stats[key] = minetest.parse_json(storage:get_string(key))
		end
		ctf.needs_save = true
	end

	-- Make sure all tables are present
	ctf_stats.players = ctf_stats.players or {}
	if not ctf_stats.current then
		local current = {}
		for team in pairs(ctf.teams) do
			current[team] = {}
		end
		ctf_stats.current = current
	end

	ctf_stats.start = os.time()

	-- Strip players which have no score
	for name, player_stats in pairs(ctf_stats.players) do
		if not player_stats.score or player_stats.score <= 0 then
			ctf_stats.players[name] = nil
			ctf.needs_save = true
		else
			player_stats.bounty_kills = player_stats.bounty_kills or 0
		end
	end
end

ctf.register_on_save(function()
	for _, key in pairs(data_to_persist) do
		storage:set_string(key, minetest.write_json(ctf_stats[key]))
	end

	return nil
end)

function ctf_stats.player_or_nil(name)
	local playerstats = ctf_stats.players[name]
	for _, stats in pairs(ctf_stats.current) do
		if stats[name] then
			return playerstats, stats[name]
		end
	end
	return playerstats
end

-- Returns a tuple: `player_stats`, `match_player_stats`
function ctf_stats.player(name)
	local player_stats = ctf_stats.players[name]
	if not player_stats then
		player_stats = {
			name = name,
			kills = 0,
			deaths = 0,
			captures = 0,
			attempts = 0,
			score = 0,
			bounty_kills = 0,
		}
		ctf_stats.players[name] = player_stats
	end

	local match_player_stats
	for _, stats in pairs(ctf_stats.current) do
		if stats[name] then
			match_player_stats = stats[name]
			break
		end
	end

	return player_stats, match_player_stats
end

ctf.register_on_join_team(function(name, tname)
	ctf_stats.current[tname][name] = ctf_stats.current[tname][name] or {
		kills = 0,
		kills_since_death = 0,
		deaths = 0,
		attempts = 0,
		captures = 0,
		score = 0,
		bounty_kills = 0,
	}
end)

local winner_team = "-"
local winner_player = "-"

ctf_flag.register_on_capture(function(name, flag)
	local main, match = ctf_stats.player(name)
	if main and match then
		main.captures  = main.captures  + 1
		main.score     = main.score     + 25
		match.captures = match.captures + 1
		match.score    = match.score    + 25
		ctf.needs_save = true
	end
	winner_player = name
end)

local prev_match_summary = storage:get_string("prev_match_summary")
ctf_match.register_on_winner(function(winner)
	ctf.needs_save = true
	winner_team = winner

	-- Show match summary
	local fs = ctf_stats.get_formspec_match_summary(ctf_stats.current,
					winner_team, winner_player, os.time() - ctf_stats.start)
	for _, player in pairs(minetest.get_connected_players()) do
		minetest.show_formspec(player:get_player_name(), "ctf_stats:eom", fs)
	end

	-- Set prev_match_summary and write to mod_storage
	prev_match_summary = fs
	storage:set_string("prev_match_summary", fs)
end)

ctf_match.register_on_skip_map(function()
	ctf.needs_save = true

	-- Show match summary
	local fs = ctf_stats.get_formspec_match_summary(ctf_stats.current,
					winner_team, winner_player, os.time()-ctf_stats.start)
	for _, player in pairs(minetest.get_connected_players()) do
		minetest.show_formspec(player:get_player_name(), "ctf_stats:eom", fs)
	end

	-- Set prev_match_summary and write to mod_storage
	prev_match_summary = fs
	storage:set_string("prev_match_summary", fs)
end)

ctf_match.register_on_create_teams(function()
	local current_stats = {}
	for _, team in ipairs(ctf.team_list) do
		current_stats[team] = {}
	end
	ctf_stats.current = current_stats
	winner_team = "-"
	winner_player = "-"
	ctf_stats.start = os.time()
	ctf.needs_save = true
end)

ctf_flag.register_on_pick_up(function(name, flag)
	local main, match = ctf_stats.player(name)
	if main and match then
		main.attempts  = main.attempts  + 1
		main.score     = main.score     + 10
		match.attempts = match.attempts + 1
		match.score    = match.score    + 10
		ctf.needs_save = true
	end
end)

-- good_weapons now includes all mese and diamond implements, and swords of steel and better
local good_weapons = {
	"default:sword_steel",
	"default:sword_bronze",
	"default:sword_mese",
	"default:sword_diamond",
	"default:pick_mese",
	"default:pick_diamond",
	"default:axe_mese",
	"default:axe_diamond",
	"default:shovel_mese",
	"default:shovel_diamond",
	"shooter:grenade",
	"shooter:shotgun",
	"shooter:rifle",
	"shooter:machine_gun",
}

local function invHasGoodWeapons(inv)
	for _, weapon in pairs(good_weapons) do
		if inv:contains_item("main", weapon) then
			return true
		end
	end
	return false
end

local function calculateKillReward(victim, killer)
	local vmain, victim_match = ctf_stats.player(victim)

	-- +5 for every kill they've made since last death in this match.
	local reward = victim_match.kills_since_death * 5
	ctf.log("ctf_stats", "Player " .. victim .. " has made " .. reward ..
			" score worth of kills since last death")

	-- 30 * K/D ratio, with variable based on player's score
	local kdreward = 30 * vmain.kills / (vmain.deaths + 1)
	local max = vmain.score / 6
	if kdreward > max then
		kdreward = max
	end
	if kdreward > 80 then
		kdreward = 80
	end
	reward = reward + kdreward

	-- Limited to  0 <= X <= 200
	if reward > 200 then
		reward = 200
	elseif reward < 14 then
		reward = 14
	end

	-- Half if no good weapons
	local inv = minetest.get_inventory({ type="player", name = victim })
	if not invHasGoodWeapons(inv) then
		ctf.log("ctf_stats", "Player " .. victim .. " has no good weapons")
		reward = reward * 0.5
	else
		ctf.log("ctf_stats", "Player " .. victim .. " has good weapons")
	end

	return reward
end

ctf.register_on_killedplayer(function(victim, killer)
	-- Suicide is not encouraged here at CTF
	if victim == killer then
		return
	end
	local main, match = ctf_stats.player(killer)
	if main and match then
		local reward = calculateKillReward(victim, killer)
		main.kills  = main.kills  + 1
		main.score  = main.score  + reward
		match.kills = match.kills + 1
		match.score = match.score + reward
		match.kills_since_death = match.kills_since_death + 1
		ctf.needs_save = true
	end
end)

minetest.register_on_dieplayer(function(player)
	local main, match = ctf_stats.player(player:get_player_name())
	if main and match then
		main.deaths = main.deaths + 1
		match.deaths = match.deaths + 1
		match.kills_since_death = 0
		ctf.needs_save = true
	end
end)

minetest.register_chatcommand("summary", {
	func = function (name, param)
		if not prev_match_summary then
			return false, "Couldn't find the requested data."
		end

		minetest.show_formspec(name, "ctf_stats:prev_match_summary", prev_match_summary)
	end
})

ctf_stats.load()

dofile(minetest.get_modpath("ctf_stats").."/gui.lua")

--
--- Team set/get
--

---@param player string | ObjectRef
---@param teamname string | nil
function ctf_teams.set_team(player, teamname)
	player = PlayerName(player)

	if not teamname then
		ctf_teams.player_team[player] = nil
		return
	end

	assert(type(teamname) == "string")
	if not (ctf_teams.player_team[player] and ctf_teams.player_team[player].locked) then
		ctf_teams.player_team[player] = {
			name = teamname,
		}

		RunCallbacks(ctf_teams.registered_on_allocplayer, PlayerObj(player), teamname)
	end
end

---@param player string | ObjectRef
---@return boolean | string
function ctf_teams.get_team(player)
	player = PlayerName(player)

	if ctf_teams.player_team[player] then
		return ctf_teams.player_team[player].name
	end

	return false
end

--
--- Allocation
--

local team_list = {}
local tpos = 1
function ctf_teams.allocate_player(player)
	if #team_list <= 0 then return end -- No teams initialized yet

	ctf_teams.set_team(player, team_list[tpos])

	if tpos >= #team_list then
		tpos = 1
	else
		tpos = tpos + 1
	end
end

function ctf_teams.dealloc_player(player)
	RunCallbacks(ctf_teams.registered_on_deallocplayer, PlayerObj(player), ctf_teams.get_team(player))

	ctf_teams.set_team(player, nil)
end

---@param teams table
-- Should only be called at match start
function ctf_teams.allocate_teams(teams, on_alloc_callback)
	local players = minetest.get_connected_players()
	team_list = {}
	tpos = 1

	for teamname, def in pairs(teams) do
		table.insert(team_list, teamname)
	end

	table.shuffle(players)
	for _, player in ipairs(players) do
		ctf_teams.allocate_player(player)
	end
end

--
--- Other
--

---@param teamname string Name of team
---@return boolean | table,table
--- Returns 'false' if there is no current map.
---
--- Example usage: `pos1, pos2 = ctf_teams.get_team_territory("red")`
function ctf_teams.get_team_territory(teamname)
	local current_map = ctf_map.current_map
	if not current_map then return false end

	return current_map.teams[teamname].pos1, current_map.teams[teamname].pos2
end

minetest.register_on_leaveplayer(function(player)
	ctf_teams.dealloc_player(player)
end)

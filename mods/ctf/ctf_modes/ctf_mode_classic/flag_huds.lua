local hud = mhud.init()

local FLAG_SAFE             = {color = 0xFFFFFF, text = "Punch the enemy flag! Protect your flag!"           }
local FLAG_STOLEN           = {color = 0xFF0000, text = "Kill %s, they've got your flag!"                    }
local FLAG_STOLEN_YOU       = {color = 0xFF0000, text = "You've got the flag! Run back and punch your flag!" }
local FLAG_STOLEN_TEAMMATE  = {color = 0x22BB22, text = "Protect %s! They have the enemy flag!"              }
local BOTH_FLAGS_STOLEN     = {color = 0xFF0000, text = "Kill %s to allow %s to capture the flag!"           }
local BOTH_FLAGS_STOLEN_YOU = {color = 0xFF0000, text = "You can't capture the flag until %s is killed!"     }

local function other(team)
	if team == "red" then
		return "blue"
	else
		return "red"
	end
end

local function get_status(you)
	local teamname = ctf_teams.get(you)

	if not teamname then return end

	local enemy_thief = ctf_modebase.flag_taken[teamname]
	local your_thief = ctf_modebase.flag_taken[other(teamname)]
	local status

	if enemy_thief then
		if your_thief then
			if your_thief == you then
				status = BOTH_FLAGS_STOLEN_YOU
				status.text = status.text:format(enemy_thief)
			else
				status = BOTH_FLAGS_STOLEN
				status.text = status.text:format(enemy_thief, your_thief)
			end
		else
			status = FLAG_STOLEN
			status.text = status.text:format(enemy_thief)
		end
	else
		if your_thief then
			if your_thief == you then
				status = FLAG_STOLEN_YOU
			else
				status = FLAG_STOLEN_TEAMMATE
				status.text = status.text:format(your_thief)
			end
		else
			status = FLAG_SAFE
		end
	end

	return status
end

return {
	on_allocplayer = function(player)
		local status = get_status(player:get_player_name())

		if not hud:exists(player, "flag_status") then
			hud:add(player, "flag_status", {
				hud_elem_type = "text",
				position = {x = 1, y = 0},
				offset = {x = -6, y = 6},
				alignment = {x = "left", y = "down"},
				text = status.text,
				color = status.color,
			})
		else
			hud:change(player, "flag_status", status)
		end

		for tname, def in pairs(ctf_map.current_map.teams) do
			local flag_pos = table.copy(def.flag_pos)

			if not hud:exists(player, "flag_pos:"..tname) then
				hud:add(player, "flag_pos:"..tname, {
					hud_elem_type = "waypoint",
					waypoint_text = HumanReadable(tname).."'s base",
					color = ctf_teams.team[tname].color_hex,
					world_pos = flag_pos,
				})
			else
				hud:change(player, "flag_pos:"..tname, {
					world_pos = flag_pos,
				})
			end
		end
	end,
	update = function()
		for _, player in pairs(minetest.get_connected_players()) do
			hud:change(player, "flag_status", get_status(player:get_player_name()))
		end
	end,
}

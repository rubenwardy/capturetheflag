local respawn_delay = {}
local hud = mhud.init()

local function run_respawn_timer(pname)
	if not respawn_delay[pname] then return end

	local player = minetest.get_player_by_name(pname)

	respawn_delay[pname] = respawn_delay[pname] - 1

	if respawn_delay[pname] > 0 then
		hud:change(pname, "timer", {
			text = string.format("Respawning in %ds", respawn_delay[pname])
		})

		minetest.after(1, run_respawn_timer, pname)
	else
		hud:remove(pname, "timer")

		respawn_delay[pname] = "done"
		RunCallbacks(minetest.registered_on_respawnplayers, player)
	end
end

-- Returns false if player can be respawned normally, true otherwise
function ctf_modebase.delay_respawn(player, time, waiting_pos)
	player = PlayerObj(player)
	local pname = player:get_player_name()

	if respawn_delay[pname] then
		if respawn_delay[pname] == "done" then
			respawn_delay[pname] = nil

			return false
		else
			return true
		end
	end

	respawn_delay[pname] = time

	hud:add(pname, "timer", {
		hud_elem_type = "text",
		position = {x = 0.5, y = 0.1},
		alignment = {x = "center", y = "down"},
		text_scale = 2,
		color = 0xA000B3,
	})

	player:set_pos(waiting_pos)

	run_respawn_timer(pname)

	return true
end

minetest.register_on_leaveplayer(function(player)
	respawn_delay[player:get_player_name()] = nil
end)

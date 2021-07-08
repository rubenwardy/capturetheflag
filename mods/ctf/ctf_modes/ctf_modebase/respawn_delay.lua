local respawn_delay = {}
local hud = mhud.init()

local function run_respawn_timer(pname)
	if not respawn_delay[pname] then return end

	local player = minetest.get_player_by_name(pname)

	respawn_delay[pname].timer = respawn_delay[pname].timer - 1

	if respawn_delay[pname].timer > 0 then
		hud:change(pname, "timer", {
			text = string.format("Respawning in %ds", respawn_delay[pname].timer)
		})

		minetest.after(1, run_respawn_timer, pname)
	else
		hud:remove(pname, "timer")

		respawn_delay[pname].state = "done"
		RunCallbacks(minetest.registered_on_respawnplayers, player)
	end
end

function ctf_modebase.prep_delayed_respawn(player)
	player = PlayerObj(player)
	local pname = player:get_player_name()

	respawn_delay[pname] = {state = "prepped", hp_max = player:get_properties().hp_max}

	player:set_properties({
		hp_max = 0,
		pointable = false,
	})

	physics.set(pname, "ctf_modebase:respawn_freeze", {speed = 0, jump = 0.5})
end

-- Returns false if timer is up, true if timer is ongoing
function ctf_modebase.delay_respawn(player, time, immunity_after)
	player = PlayerObj(player)
	local pname = player:get_player_name()

	if respawn_delay[pname] then
		if respawn_delay[pname].state == "done" then
			local hp_max = respawn_delay[pname].hp_max

			player:set_properties({
				hp_max = hp_max,
				pointable = not immunity_after and true,
			})
			physics.remove(pname, "ctf_modebase:respawn_freeze")

			minetest.after(0, function()
				if player then
					player:set_hp(hp_max)
				end
			end)

			if immunity_after then
				minetest.after(immunity_after, function()
					if player then
						player:set_properties({
							pointable = true
						})
					end
				end)
			end

			respawn_delay[pname] = nil

			return false
		elseif respawn_delay[pname].state == "in_progress" then
			return true
		end
	else
		ctf_modebase.prep_delayed_respawn(pname)
	end

	respawn_delay[pname].timer = time
	respawn_delay[pname].state = "in_progress"

	hud:add(pname, "timer", {
		hud_elem_type = "text",
		position = {x = 0.5, y = 0.1},
		alignment = {x = "center", y = "down"},
		text_scale = 2,
		color = 0xA000B3,
	})

	run_respawn_timer(pname)

	return true
end

minetest.register_on_leaveplayer(function(player)
	respawn_delay[player:get_player_name()] = nil
end)

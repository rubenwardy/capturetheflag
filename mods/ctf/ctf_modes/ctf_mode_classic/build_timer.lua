local hud = mhud.init()

local BUILD_TIME = 3 * 60

local target_map
local timer
local second_timer = 0

local build_timer = {
	start = function(mapdef)
		timer = BUILD_TIME
		target_map = mapdef
	end,
	in_progress = function()
		return timer ~= nil
	end,
	finish = function()
		timer = nil

		if target_map then
			ctf_map.remove_barrier(target_map)
			target_map = nil
		end
	end
}

minetest.register_globalstep(function(dtime)
	if not timer then return end

	timer = timer - dtime
	second_timer = second_timer + dtime

	if timer <= 0 then
		timer = nil
		second_timer = 0

		hud:remove_all()

		build_timer.finish()
		return
	end

	if second_timer >= 1 then
		second_timer = 0

		for _, player in pairs(minetest.get_connected_players()) do
			local time_str = string.format("%dm %ds until match begins!", math.floor(timer / 60), math.floor(timer % 60))

			if not hud:exists(player, "build_timer") then
				hud:add(player, "build_timer", {
					hud_elem_type = "text",
					position = {x = 0.5, y = 0.5},
					offset = {x = 0, y = -42},
					alignment = {x = "center", y = "up"},
					text = time_str,
					color = 0xFFFFFF,
				})
			else
				hud:change(player, "build_timer", {
					text = time_str
				})
			end
		end
	end
end)

return build_timer

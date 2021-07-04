ctf_combat_mode = {}

local hud = mhud.init()

local in_combat = {}

local function update_hud(player, time)
	player = PlayerName(player)

	if time <= 0 then
		return ctf_combat_mode.remove(player)
	end

	local hud_message = "You are in combat [%ds]"

	if hud:exists(player, "combat_indicator") then
		hud:change(player, "combat_indicator", {
			text = hud_message:format(time)
		})
	else
		hud:add(player, "combat_indicator", {
			hud_elem_type = "text",
			position = {x = 1, y = 0.2},
			alignment = {x = "left", y = "down"},
			offset = {x = -6, y = 0},
			text = hud_message:format(time),
			color = 0xF00000,
		})
	end

	minetest.after(1, function()
		if in_combat[player] then
			in_combat[player].time = in_combat[player].time - 1
			update_hud(player, in_combat[player].time)
		end
	end)
end

function ctf_combat_mode.set(player, time, extra)
	player = PlayerName(player)

	if not in_combat[player] then
		in_combat[player] = {time = time, extra = extra}
		update_hud(player, time)
	else
		in_combat[player].time = time
	end
end

function ctf_combat_mode.get(player)
	return in_combat[PlayerName(player)]
end

function ctf_combat_mode.remove(player)
	in_combat[PlayerName(player)] = nil

	if hud:get(player, "combat_indicator") then
		hud:remove(player, "combat_indicator")
	end
end

minetest.register_on_leaveplayer(function(player)
	in_combat[player:get_player_name()] = nil
end)

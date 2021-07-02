local hud = mhud.init()

local MAX_NAME_LENGTH = 19
local HUD_LINES = 6
local HUD_LINE_HEIGHT = 36
local HUD_DEFINITIONS = {
	{
		hud_elem_type = "text",
		position = {x = 0, y = 0.8},
		offset = {x = MAX_NAME_LENGTH*10, y = 0},
		alignment = {x = "left", y = "center"},
		color = 0xFFF,
	},
	{
		hud_elem_type = "image",
		position = {x = 0, y = 0.8},
		image_scale = 2,
		offset = {x = (MAX_NAME_LENGTH*10) + 29, y = 0},
		alignment = {x = "center", y = "center"},
	},
	{
		hud_elem_type = "text",
		position = {x = 0, y = 0.8},
		offset = {x = (MAX_NAME_LENGTH*10) + 54, y = 0},
		alignment = {x = "right", y = "center"},
		color = 0xFFF,
	},
}

local kill_list = {}
local function add_kill(x, y, z)
	table.insert(kill_list, 1, {x, y, z})

	if #kill_list == HUD_LINES then
		table.remove(kill_list)
	end
end

local function update_hud_line(player, idx, new)
	idx = HUD_LINES - (idx-1)

	for i=1, 3, 1 do
		local hname = string.format("kill_list:%d,%d", idx, i)
		local phud = hud:get(player, hname)

		if phud then
			hud:change(player, hname, {
				offset = {x = phud.def.offset.x, y = -(idx-1)*HUD_LINE_HEIGHT},
				text = (new[i].text or new[i]),
				color = new[i].color or 0xFFF
			})
		else
			local newhud = table.copy(HUD_DEFINITIONS[i])


			newhud.offset.y = -(idx-1)*HUD_LINE_HEIGHT
			newhud.text = new[i].text or new[i]
			newhud.color = new[i].color or 0xFFF
			hud:add(player, hname, newhud)
		end
	end
end

local function update_kill_list_hud(player)
	for i=1, HUD_LINES, 1 do
		if kill_list[i] then
			update_hud_line(player, i, kill_list[i])
		end
	end
end

local function update_all_kill_list_huds()
	for _, player in pairs(minetest.get_connected_players()) do
		update_kill_list_hud(player)
	end
end

ctf_modebase.register_on_new_match(function()
	kill_list = {}

	hud:clear_all()
end)

minetest.register_on_joinplayer(function(player)
	update_kill_list_hud(player)
end)

local damage_group_textures = {grenade = "grenades_frag.png"}
function ctf_modebase.add_kill(player, hitter, time_from_last_punch, tool_capabilities)
	local hp = player:get_hp()

	if hp > 0 and hitter and hitter:is_player() and hp - damage <= 0 then
		local k_teamcolor = ctf_teams.get(hitter)
		local v_teamcolor = ctf_teams.get(player)

		local killwep_invimage

		for group, texture in pairs(damage_group_textures) do
			if tool_capabilities.damage_groups[group] then
				killwep_invimage = texture
				break
			end
		end

		if not killwep_invimage then
			killwep_invimage = hitter:get_wielded_item():get_definition().inventory_image or "default_tool_steelsword.png"
		end

		if k_teamcolor then
			k_teamcolor = ctf_teams.team[k_teamcolor].color_hex
		end
		if v_teamcolor then
			v_teamcolor = ctf_teams.team[v_teamcolor].color_hex
		end

		if killwep_invimage == "" then
			killwep_invimage = nil
		end

		add_kill(
			{text = hitter:get_player_name(), color = k_teamcolor or nil},
			killwep_invimage,
			{text = player:get_player_name(), color = v_teamcolor or nil}
		)
	end
end

minetest.register_on_dieplayer(function(player, reason)
	local v_teamcolor = ctf_teams.get(player)

	if v_teamcolor then
		v_teamcolor = ctf_teams.team[v_teamcolor].color_hex
	end

	if reason.type ~= "punch" then
		add_kill("", "ctf_modebase_skull.png", {text = player:get_player_name(), color = v_teamcolor or nil})
	end


	update_all_kill_list_huds()
end)

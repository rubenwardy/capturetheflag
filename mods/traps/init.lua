minetest.register_node("traps:dirt", {
	description = "Unwalkable Dirt",
	tiles = {"traps_dirt.png"},
	is_ground_content = false,
	walkable = false,
	groups = {crumbly=3, soil=1}
})

minetest.register_node("traps:stone", {
	description = "Unwalkable Stone",
	tiles = {"traps_stone.png"},
	is_ground_content = false,
	walkable = false,
	groups = {cracky=3, stone=1}
})

minetest.register_node("traps:cobble", {
	description = "Unwalkable Cobblestone",
	tiles = {"traps_cobble.png"},
	is_ground_content = false,
	walkable = false,
	groups = {cracky=3, stone=2}
})

minetest.register_node("traps:spike", {
	description = "Spike",
	drawtype = "plantlike",
	tiles = {"traps_spike.png"},
	inventory_image = "traps_spike.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	damage_per_second = 5,
	groups = {cracky=1, level=2},
	selection_box = {
		type = "fixed",
		fixed = {-6 / 16, -0.5, -6 / 16, 6 / 16, -3 / 16, 6 / 16},
	},
})

minetest.register_node("traps:damage_cobble", {
	description = "Cobblestone that damages digger",
	tiles = {"traps_dmg_cobble.png"},
	is_ground_content = false,
	walkable = true,
	groups = {cracky=3, stone=2},
	on_dig = function(pos, node, digger)
		local name = digger:get_player_name()
		if not digger then
			return
		end

		local digger_team = ctf.player(name).team
		local meta = minetest.get_meta(pos)
		local placer_team = meta:get_string("placer") or "missing"
		if digger_team ~= placer_team then
			local hp = digger:get_hp()
			digger:set_hp(hp - 7)
			minetest.remove_node(pos)
			return
		end

		meta:set_string("placer", "")
		return minetest.node_dig(pos, node, digger)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		local name = placer:get_player_name()
		meta:set_string("placer", ctf.player(name).team)
	end
})

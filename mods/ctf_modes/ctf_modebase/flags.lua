local function flag_on_punch(pos, node, puncher, pointed_thing)
	local above = vector.offset(pos, 0, 1, 0)
	if node.name == "ctf_modebase:flag" and not minetest.get_node(above).name:find("ctf_modebase") then

	end
end

-- The flag
minetest.register_node("ctf_modebase:flag", {
	description = "Flag",
	drawtype="nodebox",
	paramtype = "light",
	walkable = false,
	tiles = {
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png"
	},
	node_box = {
		type = "fixed",
		fixed = {
			{0.250000,-0.500000,0.000000,0.312500,0.500000,0.062500}
		}
	},
	groups = {immortal=1,is_flag=1,flag_bottom=1},
	on_punch = flag_on_punch,
})

for name, def in pairs(ctf_teams.team) do
	local color = def.color
	minetest.register_node("ctf_modebase:flag_top_"..name,{
		description = "You are not meant to have this! - flag top",
		drawtype="nodebox",
		paramtype = "light",
		walkable = false,
		tiles = {
			"default_wood.png",
			"default_wood.png",
			"default_wood.png",
			"default_wood.png",
			"default_wood.png^(wool_white.png^[colorize:"..color..":200^[mask:flag_mask.png)",
			"default_wood.png^(wool_white.png^[colorize:"..color..":200^[mask:flag_mask2.png)"
		},
		node_box = {
			type = "fixed",
			fixed = {
				{0.250000,-0.500000,0.000000,0.312500,0.500000,0.062500},
				{-0.5,0,0.000000,0.250000,0.500000,0.062500}
			}
		},
		groups = {immortal=1,is_flag=1,flag_top=1,not_in_creative_inventory=1},
		on_punch = flag_on_punch,
	})
end

minetest.register_node("ctf_modebase:flag_captured_top",{
	description = "You are not meant to have this! - flag captured",
	drawtype = "nodebox",
	paramtype = "light",
	walkable = false,
	tiles = {
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png"
	},
	node_box = {
		type = "fixed",
		fixed = {
			{0.250000,-0.500000,0.000000,0.312500,0.500000,0.062500}
		}
	},
	groups = {immortal=1,is_flag=1,flag_top=1,not_in_creative_inventory=1},
	on_punch = function(pos, node, puncher, pointed_thing)
		minetest.chat_send_player(PlayerName(puncher), "This flag was taken!")
	end,
})

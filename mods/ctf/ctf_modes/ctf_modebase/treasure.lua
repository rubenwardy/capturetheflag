ctf_map.treasurefy_node = function(pos, node, clicker)
	if not ctf_modebase.current_mode then return end

	local meta = minetest.get_meta(pos)

	for _, func in ipairs(ctf_modebase.registered_on_treasurefy_node) do
		if not func(pos) then -- return true to disable default treasures
			local inv = meta:get_inventory()

			for item, def in pairs(ctf_modebase.modes[ctf_modebase.current_mode].treasures or {}) do

				for c = 1, def.max_stacks or 1, 1 do
					if math.random(1, 100) < (def.rarity or 0.5) * 100 then
						local treasure = ItemStack(item)
						treasure:set_count(math.random(def.min_count or 1, def.max_count))
						inv:add_item("main", treasure)
					end
				end
			end
		end
	end
end

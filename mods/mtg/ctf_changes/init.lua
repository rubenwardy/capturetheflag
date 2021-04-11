local DISALLOW_MOD_ABMS = {"default", "fire", "flowers", "tnt"}

minetest.register_on_mods_loaded(function()

	-- Remove Unneeded ABMs

	local remove_list = {}

	for key, abm in pairs(minetest.registered_abms) do
		for _, mod in pairs(DISALLOW_MOD_ABMS) do
			if abm.mod_origin == mod then
				table.insert(remove_list, key)
				break
			end
		end
	end

	local removed = 0
	for _, key in pairs(remove_list) do
		table.remove(minetest.registered_abms, key - removed)
		removed = removed + 1
	end

	-- Unset falling group for all nodes

	for name, def in pairs(minetest.registered_nodes) do
		if def.groups then
			def.groups.falling_node = nil
			minetest.override_item(name, {groups = def.groups})
		end

		if name:find("fire:") and def.on_timer then
			def.on_timer = nil
		end
	end
end)

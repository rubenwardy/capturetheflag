function ctf_modebase.place_map(mapidx)
	local dirlist = minetest.get_dir_list(ctf_map.maps_dir, true)

	if not mapidx then
		mapidx = math.random(1, #dirlist)
	elseif type(mapidx) ~= "number" then
		mapidx = table.indexof(dirlist, mapidx)
	end

	local map = ctf_map.place_map(mapidx, dirlist[mapidx])

	ctf_map.announce_map(map)
end

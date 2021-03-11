ctf_core = {
	settings = {
		server_mode = minetest.settings:get("ctf_server_mode")
	}
}

---@param files table
function ctf_core.include_files(files)
	for _, file in ipairs(files) do
		dofile(minetest.get_modpath(minetest.get_current_modname()).."/"..file)
	end
end

ctf_core.include_files({"helpers.lua"})

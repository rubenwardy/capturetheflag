local backend = minetest.settings:get("ctf_rankings_backend") or "default"

local rankings = ctf_core.include_files(backend..".lua")

ctf_rankings = {
	init = function()
		return rankings:init_new()
	end,
}

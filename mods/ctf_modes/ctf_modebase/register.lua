function ctf_modebase.register_mode(name, def)
	ctf_modebase.modes[name] = def
	table.insert(ctf_modebase.modelist, name)
end

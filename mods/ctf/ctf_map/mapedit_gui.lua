local DEFAULT_ELEMSIZE = {3, 0.7}
local SCROLLBAR_WIDTH = 0.6
local skyboxes = {"none"}

minetest.register_on_mods_loaded(function()
	local skyboxlist = skybox.get_skies()

	for _, s in ipairs(skyboxlist) do
		table.insert(skyboxes, s[1])
	end
end)

local context = {}
function ctf_map.show_mapedit_form(player, form, formdef)
	player = PlayerName(player)

	formdef.formname = "ctf_map:"..form
	if formdef.elements then
		if not context[player] then context[player] = {} end

		context[player].form = formdef
	end

	local maxyscroll = 0
	local formspec = "formspec_version[4]" ..
			"size[10,8]" ..
			"label[0.1,0.5;CaptureTheFlag Map Editor]" ..
			"label[0.1,1.5;"..formdef.description.."]" ..
			"scroll_container[0.1,2;9.4,8;formcontent;vertical]"

	if formdef.elements then
		for id, def in pairs(formdef.elements) do
			id = minetest.formspec_escape(id)

			if def.pos then
				if def.pos[2] > maxyscroll then
					maxyscroll = def.pos[2]
				end
			end

			if not def.size then def.size = DEFAULT_ELEMSIZE end

			if def.type == "label" then
				if def.centered then
					formspec = formspec .. string.format(
						"style[%s;border=false]" ..
						"button[%f,%d;%f,%f;%s;Text]",
						id,
						def.pos[1],
						def.pos[2],
						def.size[1],
						def.size[2],
						id,
						minetest.formspec_escape(def.label)
					)
				else
					formspec = formspec .. string.format(
						"label[%f,%f;%s]",
						def.pos[1],
						def.pos[2],
						minetest.formspec_escape(def.label)
					)
				end
			elseif def.type == "field" then
				formspec = formspec .. string.format(
					"field_close_on_enter[%s;%s]"..
					"field[%f,%f;%f,%f;%s;%s;%s]",
					id,
					def.close_on_enter == true and "true" or "false",
					def.pos[1],
					def.pos[2],
					def.size[1],
					def.size[2],
					id,
					minetest.formspec_escape(def.label or ""),
					minetest.formspec_escape(def.default or "")
				)
			elseif def.type == "button" then
				formspec = formspec .. string.format(
					"button%s[%f,%f;%f,%f;%s;%s]",
					def.exit and "_exit" or "",
					def.pos[1],
					def.pos[2],
					def.size[1],
					def.size[2],
					id,
					minetest.formspec_escape(def.label)
				)
			elseif def.type == "dropdown" then
				formspec = formspec .. string.format(
					"dropdown[%f,%f;%f,%f;%s;%s;%d;%s]",
					def.pos[1],
					def.pos[2],
					def.size[1],
					def.size[2],
					id,
					table.concat(def.items, ","),
					def.startidx or 1,
					def.give_idx and "true" or "false"
				)
			elseif def.type == "checkbox" then
				formspec = formspec .. string.format(
					"checkbox[%f,%f;%s;%s;%s]",
					def.pos[1],
					def.pos[2],
					id,
					minetest.formspec_escape(def.label),
					def.default or false
				)
			end
		end
	end
	formspec = formspec .. "scroll_container_end[]"

	-- Add scrollbar if needed
	if maxyscroll > 9 then
		if not formdef.scroll_pos then
			formdef.scroll_pos = 0
		elseif formdef.scroll_pos == "max" then
			formdef.scroll_pos = formdef.scrollheight or 500
		end

		formspec = formspec .. "scrollbaroptions[max=" .. (formdef.scrollheight or 500) ..";]" ..
				"scrollbar[9.5,0;"..(SCROLLBAR_WIDTH - 0.1)..",8;vertical;formcontent;" .. formdef.scroll_pos .. "]"
	end

	minetest.close_formspec(player, formdef.formname)
	minetest.show_formspec(player, formdef.formname, formspec)
end

function ctf_map.show_map_editor(player)
	if context[player] and context[player].map then
		ctf_map.show_map_save_form(player)
		return
	end

	local dirlist = minetest.get_dir_list(ctf_map.maps_dir, true)
	local dirlist_sorted = dirlist
	table.sort(dirlist_sorted)

	ctf_map.show_mapedit_form(player, "start", {
		description = "Would you like to edit an existing map or create a new one?",
		close_after_fields = true,
		elements = {
			newmap = {
				type = "button", exit = true, label = "Create New Map", pos = {0, 0},
				func = function(pname)
					minetest.chat_send_player(pname,
							"Please decide what the size of your map will be and punch nodes on two opposite corners of it")
					ctf_map.get_pos_from_player(pname, 2, function(p, positions)
						local pos1, pos2 = vector.sort(positions[1], positions[2])

						context[p].map = {
							pos1          = pos1,
							pos2          = pos2,
							enabled       = false,
							dirname       = "new_map",
							name          = "My New Map",
							author        = player,
							hint          = "hint",
							license       = "CC-BY",
							others        = "Other info",
							base_node     = "ctf_map:ignore",
							initial_stuff = {},
							treasures     = {},
							skybox        = "none",
							-- Also see the save form for defaults
							start_time    = ctf_map.DEFAULT_START_TIME,
							time_speed    = 1,
							phys_speed    = 1,
							phys_jump     = 1,
							phys_gravity  = 1,
							--
							chests        = {}
						}

						minetest.chat_send_player(pname, "Build away!")
					end)
				end,
			},
			label = {
				type = "label",
				pos = {1.4, 1.5},
				label = "Or",
			},
			editexisting = {
				type = "button", exit = true, label = "Edit Existing map", pos = {0, 2},
				func = function(pname, fields)
					local p = PlayerObj(pname)
					-- Set skybox and related on map start
					-- Test out map saving

					minetest.after(0.1, function()
						ctf_map.show_mapedit_form(pname, "loading", {
							description = "Placing map '"..fields.currentmaps.."'. This will take a few seconds..."
						})
					end)

					minetest.after(0.2, function()
						local map = ctf_map.load_map_meta(table.indexof(dirlist, fields.currentmaps), fields.currentmaps)
						local schempath = ctf_map.maps_dir .. fields.currentmaps .. "/map.mts"
						local res = minetest.place_schematic(map.pos1, schempath)

						assert(res, "Unable to place schematic, does the MTS file exist? Path: " .. schempath)

						minetest.after(2, function()
							ctf_map.announce_map(map)

							minetest.close_formspec(pname, "ctf_map:loading")

							p:set_pos(vector.add(map.pos1, vector.divide(map.size, 2)))

							skybox.set(p, table.indexof(skyboxes, map.skybox)-1)

							physics.set(pname, "ctf_map:editor_speed", {
								speed = map.phys_speed,
								jump = map.phys_jump,
								gravity = map.phys_gravity,
							})

							minetest.settings:set("time_speed", map.time_speed * 72)
							minetest.registered_chatcommands["time"].func(pname, map.start_time)
						end)

						minetest.after(10, function()
							minetest.fix_light(map.pos1, map.pos2)
						end)

						context[pname].map = map
					end)
				end,
			},
			currentmaps = {
				type = "dropdown",
				pos = {3.2, 2},
				size = {4, DEFAULT_ELEMSIZE[2]},
				items = dirlist_sorted,
			},
		}
	})
end

function ctf_map.show_map_save_form(player, scroll_pos)
	if not context[player] then
		minetest.log("error", "Cannot show save form because "..player.." is not editing a map!")
		return
	end

	if not context[player].map.teams then
		context[player].map.teams = {}
	end

	for name in pairs(ctf_teams.team) do
		if not context[player].map.teams[name] then
			context[player].map.teams[name] = {
				enabled = false,
				base_pos = vector.new(),
			}
		end
	end

	local elements = {
		positions = {
			type = "button", exit = true,
			label = "Corners - " .. minetest.pos_to_string(context[player].map.pos1, 0) ..
					" - " .. minetest.pos_to_string(context[player].map.pos2, 0),
			pos = {0, 0.5},
			size = {10 - (SCROLLBAR_WIDTH + 0.1), DEFAULT_ELEMSIZE[2]},
			func = function(pname)
				ctf_map.get_pos_from_player(pname, 2, function(p, positions)
					context[p].map.pos1 = positions[1]
					context[p].map.pos2 = positions[2]
				end)
			end,
		},
		enabled = {
			type = "checkbox", label = "Map Enabled", pos = {0, 2}, default = context[player].map.enabled,
			func = function(pname, fields, name) context[pname].map.enabled = fields[name] == "true" or false end,
		},
		dirname = {
			type = "field", label = "Folder Name", pos = {0, 3}, size = {6, 0.7}, default = context[player].map.dirname,
			func = function(pname, fields, name) context[pname].map.dirname = fields[name] end,
		},
		mapname = {
			type = "field", label = "Map Name", pos = {0, 4.4}, size = {6, 0.7}, default = context[player].map.name,
			func = function(pname, fields, name) context[pname].map.name = fields[name] end,
		},
		author = {
			type = "field", label = "Map Author(s)", pos = {0, 5.8}, size = {6, 0.7}, default = context[player].map.author,
			func = function(pname, fields, name) context[pname].map.author = fields[name] end,
		},
		hint = {
			type = "field", label = "Map Hint", pos = {0, 7.2}, size = {6, 0.7}, default = context[player].map.hint,
			func = function(pname, fields, name) context[pname].map.hint = fields[name] end,
		},
		license = {
			type = "field", label = "Map License", pos = {0, 8.6}, size = {6, 0.7}, default = context[player].map.license,
			func = function(pname, fields, name) context[pname].map.license = fields[name] end,
		},
		others = {
			type = "field", label = "Other Info", pos = {0, 10}, size = {6, 0.7}, default = context[player].map.others,
			func = function(pname, fields, name) context[pname].map.others = fields[name] end,
		},
		base_node = {
			type = "field", label = "Base Node", pos = {0, 11.4}, size = {6, 0.7}, default = context[player].map.base_node,
			func = function(pname, fields, name) context[pname].map.base_node = fields[name] end,
		},
		initial_stuff = {
			type = "field", label = "Map Initial Stuff", pos = {0, 12.8}, size = {6, 0.7},
			default = table.concat(context[player].map.initial_stuff or {"none"}, ","),
			func = function(pname, fields, name)
				context[pname].map.initial_stuff = string.split(fields[name]:gsub("%s?,%s?", ","), ",")
			end,
		},
		treasures = {
			type = "field", label = "Map Treasures", pos = {0, 14.2}, size = {6, 0.7},
			default = table.concat(context[player].map.treasures or {"none"}, ","),
			func = function(pname, fields, name)
				context[pname].map.treasures = string.split(fields[name], ",")
			end,
		},
		skybox_label = {
			type = "label",
			pos = {0, 15.4},
			label = "Skybox",
		},
		skybox = {
			type = "dropdown",
			pos = {0, 15.6},
			size = {6, DEFAULT_ELEMSIZE[2]},
			items = skyboxes,
			startidx = table.indexof(skyboxes, context[player].map.skybox),
			func = function(pname, fields, name)
				local oldval = context[pname].map.skybox
				context[pname].map.skybox = fields[name]

				if context[pname].map.skybox ~= oldval then
					skybox.set(PlayerObj(pname), table.indexof(skyboxes, fields[name])-1)
				end
			end,
		},
		speed = {
			type = "field", label = "Map Movement Speed", pos = {0, 17}, size = {4, 0.7},
			default = context[player].map.phys_speed or 1,
			func = function(pname, fields, name)
				local oldval = context[pname].map.phys_speed
				context[pname].map.phys_speed = tonumber(fields[name]) or 1

				if context[pname].map.phys_speed ~= oldval then
					physics.set(pname, "ctf_map:editor_speed", {speed = tonumber(fields[name] or 1)})
				end
			end,
		},
		jump = {
			type = "field", label = "Map Jump Height", pos = {0, 18.4}, size = {4, 0.7},
			default = context[player].map.phys_jump or 1,
			func = function(pname, fields, name)
				local oldval = context[pname].map.phys_jump
				context[pname].map.phys_jump = tonumber(fields[name]) or 1

				if context[pname].map.phys_jump ~= oldval then
					physics.set(pname, "ctf_map:editor_jump", {jump = tonumber(fields[name] or 1)})
				end
			end,
		},
		gravity = {
			type = "field", label = "Map Gravity", pos = {0, 19.8}, size = {4, 0.7},
			default = context[player].map.phys_gravity or 1,
			func = function(pname, fields, name)
				local oldval = context[pname].map.phys_gravity
				context[pname].map.phys_gravity = tonumber(fields[name]) or 1

				if context[pname].map.phys_gravity ~= oldval then
					physics.set(pname, "ctf_map:editor_gravity", {gravity = tonumber(fields[name] or 1)})
				end
			end,
		},
		start_time = {
			type = "field", label = "Map start_time", pos = {0, 21.2}, size = {4, 0.7},
			default = context[player].map.start_time or ctf_map.DEFAULT_START_TIME,
			func = function(pname, fields, name)
				local oldval = context[pname].map.start_time
				context[pname].map.start_time = fields[name] or ctf_map.DEFAULT_START_TIME

				if context[pname].map.start_time ~= oldval then
					minetest.registered_chatcommands["time"].func(pname, context[pname].map.start_time)
				end
			end,
		},
		time_speed = {
			type = "field", label = "Map time_speed (Multiplier)", pos = {0, 22.6},
			size = {4, 0.7}, default = context[player].map.time_speed or "1",
			func = function(pname, fields, name)
				local oldval = context[pname].map.time_speed
				context[pname].map.time_speed = tonumber(fields[name] or "1")

				if context[pname].map.time_speed ~= oldval then
					minetest.settings:set("time_speed", context[pname].map.time_speed * 72)
				end
			end,
		},
	}

	local idx = 24.2
	for teamname, def in pairs(context[player].map.teams) do
		elements[teamname.."_checkbox"] = {
			type = "checkbox",
			label = HumanReadable(teamname) .. " Team",
			pos = {0, idx},
			default = def.enabled,
			func = function(pname, fields, name)
				context[pname].map.teams[teamname].enabled = fields[name] == "true" or false
			end,
		}
		elements[teamname.."_button"] = {
			type = "button",
			exit = true,
			label = "Base Pos: " .. minetest.pos_to_string(def.base_pos),
			pos = {2.2, idx-(DEFAULT_ELEMSIZE[2]/2)},
			size = {5, DEFAULT_ELEMSIZE[2]},
			func = function(pname, fields)
				ctf_map.get_pos_from_player(pname, 1, function(name, positions)
					context[pname].map.teams[teamname].base_pos = positions[1]
					minetest.after(0.1, function()
						ctf_map.show_map_save_form(pname, minetest.explode_scrollbar_event(fields.formcontent).value)
					end)
				end)
			end,
		}
		idx = idx + 1
	end

	elements.addchestzone = {
		type = "button",
		exit = true,
		label = "Add Chest Zone",
		pos = {(5 - 0.2) - (DEFAULT_ELEMSIZE[1] / 2), idx},
		func = function(pname)
			table.insert(context[pname].map.chests, {
				pos1 = vector.new(),
				pos2 = vector.new(),
				amount = ctf_map.DEFAULT_CHEST_AMOUNT,
			})
			minetest.after(0.1, function()
				ctf_map.show_map_save_form(pname, "max")
			end)
		end,
	}
	idx = idx + 1

	if #context[player].map.chests > 0 then
		for id, def in pairs(context[player].map.chests) do
			elements["chestzone_"..id] = {
				type = "button",
				exit = true,
				label = "Chest Zone "..id.." - "..minetest.pos_to_string(def.pos1, 0) ..
						" - "..minetest.pos_to_string(def.pos2, 0),
				pos = {0, idx},
				size = {7, DEFAULT_ELEMSIZE[2]},
				func = function(pname, fields)
					ctf_map.get_pos_from_player(pname, 2, function(name, new_positions)
						context[pname].map.chests[id].pos1 = new_positions[1]
						context[pname].map.chests[id].pos2 = new_positions[2]

						minetest.after(0.1, function()
							ctf_map.show_map_save_form(pname, minetest.explode_scrollbar_event(fields.formcontent).value)
						end)
					end)
				end,
			}
			elements["chestzone_chests_"..id] = {
				type = "field",
				label = "Amount",
				pos = {7.2, idx},
				size = {1, DEFAULT_ELEMSIZE[2]},
				default = context[player].map.chests[id].amount,
				func = function(pname, fields, name)
					local newnum = tonumber(fields[name])
					if newnum then
						context[pname].map.chests[id].amount = newnum
					end
				end,
			}
			elements["chestzone_remove_"..id] = {
				type = "button",
				exit = true,
				label = "X",
				pos = {8.4, idx},
				size = {DEFAULT_ELEMSIZE[2], DEFAULT_ELEMSIZE[2]},
				func = function(pname, fields)
					table.remove(context[pname].map.chests, id)
					minetest.after(0.1, function()
						ctf_map.show_map_save_form(pname, minetest.explode_scrollbar_event(fields.formcontent).value)
					end)
				end,
			}
			idx = idx + 1
		end
	end

	idx = idx + 1

	elements.finishediting = {
		type = "button",
		exit = true,
		pos = {(5 - 0.2) - (DEFAULT_ELEMSIZE[1] / 2), idx},
		label = "Finish Editing",
		func = function(pname)
			minetest.after(0.1, function()
				ctf_map.save_map(context[pname].map)
				context[pname] = nil
			end)
		end,
	}

	idx = idx + 1

	-- Need to set offset
	ctf_map.show_mapedit_form(player, "save", {
		description = "Save your map. Remember to press ENTER after writing to a field",
		scrollheight = 176 + ((idx - 24) * 10) + 4,
		elements = elements,
		scroll_pos = scroll_pos or 0,
	})
end

ctf_core.register_on_formspec_input("ctf_map:", function(pname, formname, fields)
	if not context[pname] then return end

	if context[pname].form.formname == formname then
		for name, info in pairs(fields) do
			if context[pname].form.elements[name] and context[pname].form.elements[name].func then
				context[pname].form.elements[name].func(pname, fields, name)
			end
		end
	end
end)

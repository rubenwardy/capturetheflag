ctf_gui = {
	ELEM_SIZE = {3, 0.7},
	SCROLLBAR_WIDTH = 0.6,
	FORM_SIZE = {18, 12},
}

local context = {}

local gui_users_initialized = {}
function ctf_gui.init()
	local modname = minetest.get_current_modname()

	assert(not gui_users_initialized[modname], "Already initialized for mod "..dump(modname))

	gui_users_initialized[modname] = true

	ctf_core.register_on_formspec_input(modname..":", function(pname, formname, fields)
		if not context[pname] then return end

		if fields.quit and context[pname].on_quit then
			context[pname].on_quit(pname, fields)
		end

		if context[pname].formname == formname then
			for name, info in pairs(fields) do
				if context[pname].elements[name] and context[pname].elements[name].func then
					if context[pname].privs then
						local playerprivs = minetest.get_player_privs(pname)

						for priv, needed in pairs(context[pname].privs) do
							if needed and not playerprivs[priv] then
								minetest.log("warning", "Player " .. dump(pname) ..
										" doesn't have the privs needed to access the formspec " .. dump(formname))
								return
							end
						end
					end

					context[pname].elements[name].func(pname, fields, name)
				end
			end
		end
	end)
end

function ctf_gui.show_formspec(player, formname, formdef)
	player = PlayerName(player)

	formdef.formname = formname

	local maxyscroll = 0
	local formspec = "formspec_version[4]" ..
			string.format("size[%f,%f]", ctf_gui.FORM_SIZE[1], ctf_gui.FORM_SIZE[2]) ..
			"hypertext[0,0.2;"..ctf_gui.FORM_SIZE[1]-ctf_gui.SCROLLBAR_WIDTH..",1.6;title;<center><big>"..formdef.title.."</big>\n" ..
					(formdef.description or "\b") .."</center>]" ..
			"scroll_container[0.1,1.8;"..ctf_gui.FORM_SIZE[1]-ctf_gui.SCROLLBAR_WIDTH..","..ctf_gui.FORM_SIZE[2]..";formcontent;vertical]"

	local using_scrollbar = false
	if formdef.elements then
		for _, def in pairs(formdef.elements) do
			if def.pos then
				if def.pos[2] > maxyscroll then
					maxyscroll = def.pos[2]
				end
			end
		end

		using_scrollbar = maxyscroll > 9

		for id, def in pairs(formdef.elements) do
			id = minetest.formspec_escape(id)

			if not def.size then
				def.size = ctf_gui.ELEM_SIZE
			else
				if not def.size[1] then def.size[1] = ctf_gui.ELEM_SIZE[1] end
				if not def.size[2] then def.size[2] = ctf_gui.ELEM_SIZE[2] end
			end


			if def.pos[1] == "center" then
				def.pos[1] = ( (ctf_gui.FORM_SIZE[1]-(using_scrollbar and ctf_gui.SCROLLBAR_WIDTH or 0)) - def.size[1] )/2
			end

			if def.type == "label" then
				if def.centered then
					formspec = formspec .. string.format(
						"style[%s;border=false]" ..
						"button[%f,%d;%f,%f;%s;%s]",
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
					def.default_idx or 1,
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
			elseif def.type == "table" then
				local tablecolumns = {}
				local tableoptions = {}

				for _, column in ipairs(def.columns) do
					if type(column) == "table" then
						local tc_out = column.type

						column.type = nil

						for k, v in pairs(column) do
							tc_out = string.format("%s,%s=%s", tc_out, k, minetest.formspec_escape(v))
						end

						table.insert(tablecolumns, tc_out)
					else
						table.insert(tablecolumns, column)
					end
				end

				for name, option in pairs(def.options) do
					if type(tonumber(name)) ~= "number" then
						table.insert(tableoptions, string.format("%s=%s", name, option))
					else
						table.insert(tableoptions, option)
					end
				end

				formspec = formspec ..
						string.format(
							"tableoptions[%s]",
							table.concat(tableoptions, ";")
						) ..
						string.format(
							"tablecolumns[%s]",
							table.concat(tablecolumns, ";")
						) ..
						string.format(
							"table[%f,%f;%f,%f;%s;%s;%d]",
							def.pos[1],
							def.pos[2],
							def.size[1],
							def.size[2],
							id,
							table.concat(def.rows, ","),
							def.default_idx or 1
						)
			end
		end
	end
	formspec = formspec .. "scroll_container_end[]"

	-- Add scrollbar if needed
	if using_scrollbar then
		if not formdef.scroll_pos then
			formdef.scroll_pos = 0
		elseif formdef.scroll_pos == "max" then
			formdef.scroll_pos = formdef.scrollheight or 500
		end

		formspec = formspec .. "scrollbaroptions[max=" .. (formdef.scrollheight or 500) ..";]" ..
				"scrollbar["..ctf_gui.FORM_SIZE[1]-(ctf_gui.SCROLLBAR_WIDTH - 0.1)..",0;"..(ctf_gui.SCROLLBAR_WIDTH - 0.1)..","..ctf_gui.FORM_SIZE[2]..";vertical;formcontent;" .. formdef.scroll_pos .. "]"
	end

	context[player] = formdef

	minetest.close_formspec(player, formdef.formname)
	minetest.show_formspec(player, formdef.formname, formspec)
end

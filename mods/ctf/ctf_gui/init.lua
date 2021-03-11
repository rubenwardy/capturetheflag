ctf_gui = {
	ELEM_SIZE = {3, 0.7},
	SCROLLBAR_WIDTH = 0.6,
	FORM_SIZE = {10, 8},
}

local context = {}

function ctf_gui.init()
	ctf_core.register_on_formspec_input(minetest.get_current_modname()..":", function(pname, formname, fields)
		if not context[pname] then return end

		if context[pname].formname == formname then
			for name, info in pairs(fields) do
				if context[pname].elements[name] and context[pname].elements[name].func then
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
			"hypertext[0,0.2;"..10-ctf_gui.SCROLLBAR_WIDTH..",1.6;title;<center><big>"..formdef.title.."</big>\n" ..
					formdef.description.."</center>]" ..
			"scroll_container[0.1,1.8;9.4,8;formcontent;vertical]"

	if formdef.elements then
		for id, def in pairs(formdef.elements) do
			id = minetest.formspec_escape(id)

			if def.pos then
				if def.pos[2] > maxyscroll then
					maxyscroll = def.pos[2]
				end
			end

			if not def.size then def.size = ctf_gui.ELEM_SIZE end

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
				"scrollbar[9.5,0;"..(ctf_gui.SCROLLBAR_WIDTH - 0.1)..",8;vertical;formcontent;" .. formdef.scroll_pos .. "]"
	end

	context[player] = formdef

	minetest.close_formspec(player, formdef.formname)
	minetest.show_formspec(player, formdef.formname, formspec)
end

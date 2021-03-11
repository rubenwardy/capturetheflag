# CTF GUI

A tool for easily creating basic CTF-themed GUIs

# API

## Global variables

* `ctf_gui.ELEM_SIZE`       -- Default element size
* `ctf_gui.SCROLLBAR_WIDTH` -- Width of the scrollbar that appears when elements overflow the bottom of the formspec
* `ctf_gui.FORM_SIZE`       -- Size of the formspec

## Supported elements

* `label`
	```lua
	elem = {
		type = "label",
		label = "Label",  -- Label text
		centered = false, -- default: false
		pos = {x, y},     -- x can be a number or "center" to center in the formspec
		size = {x, y},    -- Only applied if centered = true. Bounds of the area the label is centered in. default: ctf_gui.ELEM_SIZE
	}
	```
* `field`
	```lua
	elem = {
		type = "field",
		close_on_enter = false, -- Exit when enter is pressed. default: false
		label = "Label",        -- Text above the field
		pos = {x, y},           -- x can be a number or "center" to center in the formspec
		size = {x, y},          -- default: ctf_gui.ELEM_SIZE
		func = function(playername, fields, field_name)
			-- Called when this element shows up in on_player_recieve_fields
		end,
	}
	```
* `button`
	```lua
	elem = {
		type = "button",
		exit = false,    -- Exit on click. default: false
		label = "Label", -- Button text
		pos = {x, y},    -- x can be a number or "center" to center in the formspec
		size = {x, y},   -- default: ctf_gui.ELEM_SIZE
		func = function(playername, fields, field_name)
			-- Called when this element shows up in on_player_recieve_fields
		end,
	}
	```
* `dropdown`
	```lua
	elem = {
		type = "dropdown",
		items = {},        -- List of strings
		default_idx = 1,   -- default: 1
		give_idx = false,  -- Controls whether idx or value of the selected string is passed to fields. default: false
		pos = {x, y},      -- x can be a number or "center" to center in the formspec
		size = {x, y},     -- default: ctf_gui.ELEM_SIZE
		func = function(playername, fields, field_name)
			-- Called when this element shows up in on_player_recieve_fields
		end,
	}
	```
* `checkbox`
	```lua
	elem = {
		type = "checkbox",
		label = "Label",   -- Label to the right of the checkbox
		default = false,   -- Default state of the checkbox. default: false
		pos = {x, y},      -- x can be a number or "center" to center in the formspec
		func = function(playername, fields, field_name)
			-- Called when this element shows up in on_player_recieve_fields
		end,
	}


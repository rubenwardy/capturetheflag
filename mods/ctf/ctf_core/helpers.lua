--
--- PLAYERS
--

function PlayerObj(player)
	local type = type(player)

	if type == "string" then
		return minetest.get_player_by_name(player)
	elseif type == "userdata" and player:is_player() then
		return player
	end
end

function PlayerName(player)
	local type = type(player)

	if type == "string" then
		return player
	elseif type == "userdata" and player:is_player() then
		return player:get_player_name()
	end
end

--
--- FORMSPECS
--

local registered_on_formspec_input = {}
function ctf_core.register_on_formspec_input(formname, func)
	table.insert(registered_on_formspec_input, {formname = formname, call = func})
end

minetest.register_on_player_receive_fields(function(player, formname, fields, ...)
	for _, func in ipairs(registered_on_formspec_input) do
		if formname:match(func.formname) then
			if func.call(PlayerName(player), formname, fields, ...) then
				return
			end
		end
	end
end)

--
--- STRINGS
--

-- Credit to https://stackoverflow.com/q/20284515/11433667 for capitalization
function HumanReadable(string)
	return string:gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
end

--
--- TABLES
--

-- Borrowed from random_messages mod
function table.count( t ) -- luacheck: ignore
	local i = 0
	for k in pairs( t ) do i = i + 1 end
	return i
end

--
--- VECTORS/POSITIONS
--

function vector.sign(a)
	return vector.new(math.sign(a.x), math.sign(a.y), math.sign(a.z))
end

local get_team = ctf_teams.get_team
local teams = ctf_teams.team
local format = string.format

---@param name string Player name
---@param rankings table Recent rankings to show in the gui
---@param rank_values table Example: `{_sort = "score", "captures" "kills"}`
---@param extra_rank_values table Not yet implemented, will be for extra unimportant rankings
function ctf_modebase.show_summary_gui(name, rankings, rank_values, extra_rank_values)
	local rows = {}
	local sort_by

	if rank_values._sort then
		table.insert(rank_values, 1, rank_values._sort)
	end

	sort_by = rank_values[1]

	for pname, ranks in pairs(rankings) do
		local team = get_team(pname)
		local color = "grey"

		if team then
			color = teams[team].color
		end

		local row = format("%s,%s", color, pname)

		for idx, rank in ipairs(rank_values) do
			if not sort_by then sort_by = rank end
			row = format("%s,%s", row, ranks[rank] or 0)
		end

		table.insert(rows, {row = row, sort = ranks[sort_by] or 0})
	end

	table.sort(rows, function(a, b) return a.sort > b.sort end)

	for i, c in pairs(rows) do
		rows[i] = format("%s,%s", i, c.row)
	end

	ctf_gui.show_formspec(name, "ctf_modebase:summary", {
		title = "Match Summary",
		elements = {
			test = {
				type = "table",
				pos = {"center", 0},
				size = {ctf_gui.FORM_SIZE[1]-1, ctf_gui.FORM_SIZE[2]-2},
				options = {
					highlight = "#00000000",
				},
				columns = {
					{type = "text", width = 1},
					{type = "color"}, -- Player team color
					{type = "text", width = 16}, -- Player name
					("text;"):rep(#rank_values):sub(1, -2),
				},
				rows = {
					"", "white", "Player Name", HumanReadable(table.concat(rank_values, "  ,")),
					table.concat(rows, ",")
				}
			}
		}
	})
end

minetest.register_chatcommand("summary", {
	description = "Show a summary for the current match",
	func = function(name, param)
		local current_mode = ctf_modebase:get_current_mode()

		if not current_mode then
			return false, "No match has started yet!"
		end

		if current_mode.summary_func then
			ctf_modebase.show_summary_gui(current_mode.summary_func(name, param))

			return true
		else
			return false, "This mode doesn't have a summary command!"
		end
	end
})

minetest.register_chatcommand("s", minetest.registered_chatcommands.summary)

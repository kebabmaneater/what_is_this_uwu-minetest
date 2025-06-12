local minetest = minetest
local what_is_this_uwu = dofile(minetest.get_modpath("what_is_this_uwu") .. "/help.lua")

local hud_type_field_name
if minetest.features.hud_def_type_field then
	-- Minetest 5.9.0 and later
	hud_type_field_name = "type"
else
	-- All Minetest versions before 5.9.0
	hud_type_field_name = "hud_elem_type"
end

local function create_hud(player)
	local pname = player:get_player_name()
	local hud = {
		background_left = player:hud_add({
			[hud_type_field_name] = "image",
			position = { x = 0.5, y = 0 },
			scale = { x = 2, y = 2 },
			text = "",
			offset = { x = -50, y = 35 },
		}),
		background_middle = player:hud_add({
			[hud_type_field_name] = "image",
			position = { x = 0.5, y = 0 },
			scale = { x = 2, y = 2 },
			text = "",
			alignment = { x = 1 },
			offset = { x = -37.5, y = 35 },
		}),
		background_right = player:hud_add({
			[hud_type_field_name] = "image",
			position = { x = 0.5, y = 0 },
			scale = { x = 2, y = 2 },
			text = "",
			offset = { x = 0, y = 35 },
		}),
		image = player:hud_add({
			[hud_type_field_name] = "image",
			position = { x = 0.5, y = 0 },
			scale = { x = 0.3, y = 0.3 },
			offset = { x = -35, y = 35 },
		}),
		name = player:hud_add({
			[hud_type_field_name] = "text",
			position = { x = 0.5, y = 0 },
			scale = { x = 0.3, y = 0.3 },
			number = 0xffffff,
			alignment = { x = 1 },
			offset = { x = 0, y = 22 },
		}),
		mod = player:hud_add({
			[hud_type_field_name] = "text",
			position = { x = 0.5, y = 0 },
			scale = { x = 0.3, y = 0.3 },
			number = 0xff3c0a,
			alignment = { x = 1 },
			offset = { x = 0, y = 37 },
			style = 2,
		}),
		best_tool = player:hud_add({
			[hud_type_field_name] = "image",
			position = { x = 0.5, y = 0 },
			scale = { x = 1, y = 1 },
			alignment = { x = 1, y = 0 },
			offset = { x = 0, y = 51 },
		}),
		tool_in_hand = player:hud_add({
			[hud_type_field_name] = "image",
			position = { x = 0.5, y = 0 },
			scale = { x = 1, y = 1 },
			alignment = { x = 1, y = 0 },
			offset = { x = 0, y = 51 },
		}),
		pointed_thing = "ignore",
	}
	what_is_this_uwu.huds[pname] = hud
	what_is_this_uwu.show_table[pname] = true
	what_is_this_uwu.possible_tools[pname] = {}
	what_is_this_uwu.possible_tool_index[pname] = 1
	what_is_this_uwu.dtimes[pname] = 0
end

local function remove_player(player)
	local pname = player:get_player_name()
	what_is_this_uwu.huds[pname] = nil
	what_is_this_uwu.prev_tool[pname] = nil
	what_is_this_uwu.show_table[pname] = nil
	what_is_this_uwu.possible_tools[pname] = nil
	what_is_this_uwu.possible_tool_index[pname] = nil
	what_is_this_uwu.dtimes[pname] = nil
end

minetest.register_on_joinplayer(create_hud)
minetest.register_on_leaveplayer(remove_player)

local function show(player, skip)
	local pname = player:get_player_name()

	local pointed_thing = what_is_this_uwu.get_pointed_thing(player)
	local hud = what_is_this_uwu.huds[pname]
	if not pointed_thing or not hud then
		what_is_this_uwu.unshow(player)
	else
		local node = minetest.get_node(pointed_thing.under)
		local node_name = node.name
		local current_tool = player:get_wielded_item():get_name()

		if hud.pointed_thing ~= node_name then
			what_is_this_uwu.possible_tool_index[pname] = 1
		end
		if hud.pointed_thing == node_name and current_tool == what_is_this_uwu.prev_tool[pname] and not skip then
			return
		end

		local form_view, item_type, node_definition = what_is_this_uwu.get_node_tiles(node_name)
		if not node_definition then
			what_is_this_uwu.unshow(player)
			return
		end

		local mod_name = what_is_this_uwu.split_item_name(node_name)
		what_is_this_uwu.prev_tool[pname] = current_tool
		what_is_this_uwu.show(player, form_view, node_name, item_type, mod_name)
	end
end

minetest.register_globalstep(function(dtime)
	for _, player in pairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()

		local dtimes = what_is_this_uwu.dtimes
		local possible_tools = what_is_this_uwu.possible_tools
		local possible_tools_index = what_is_this_uwu.possible_tool_index

		local change = minetest.settings:get("what_is_this_uwu_rate_of_change", 1.0) or 1.0
		change = tonumber(change)

		if dtimes[pname] < change then
			dtimes[pname] = dtimes[pname] + dtime
			if dtimes[pname] >= change then
				dtimes[pname] = dtimes[pname] - change
				possible_tools_index[pname] = possible_tools_index[pname] + 1
				if possible_tools_index[pname] > #possible_tools[pname] then
					possible_tools_index[pname] = 1
				end
				show(player, true)
			end
		end

		show(player, false)
	end
end)

minetest.register_chatcommand("wituwu", {
	params = "",
	description = "Show and unshow the wituwu pop-up",
	func = function(name)
		what_is_this_uwu.toggle_show(name)
		return true, "Option flipped"
	end,
})

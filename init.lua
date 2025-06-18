local minetest = minetest
dofile(minetest.get_modpath("what_is_this_uwu") .. "/spring.lua")
dofile(minetest.get_modpath("what_is_this_uwu") .. "/api.lua")
dofile(minetest.get_modpath("what_is_this_uwu") .. "/frame.lua")
local what_is_this_uwu = dofile(minetest.get_modpath("what_is_this_uwu") .. "/help.lua")
local player_hud = dofile(minetest.get_modpath("what_is_this_uwu") .. "/player_hud.lua")

local function create_hud(player)
	player:hud_set_flags({ infotext = false })
	local pname = player:get_player_name()

	what_is_this_uwu.huds[pname] = player_hud.new(player)
	what_is_this_uwu.possible_tools[pname] = {}
	what_is_this_uwu.possible_tool_index[pname] = 1
	what_is_this_uwu.dtimes[pname] = 0
end

local function remove_player(player)
	local pname = player:get_player_name()
	what_is_this_uwu.huds[pname] = nil
	what_is_this_uwu.prev_tool[pname] = nil
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
		local previous_info_text = what_is_this_uwu.prev_info_text[pname]
		local info_text = WhatIsThisApi.get_info(pointed_thing.under)

		if
			hud.pointed_thing == node_name
			and current_tool == what_is_this_uwu.prev_tool[pname]
			and not skip
			and previous_info_text == info_text
		then
			return
		end

		local form_view, item_type, node_definition = what_is_this_uwu.get_node_tiles(node_name)
		if not node_definition then
			what_is_this_uwu.unshow(player)
			return
		end

		local mod_name = what_is_this_uwu.split_item_name(node_name)
		what_is_this_uwu.prev_tool[pname] = current_tool
		what_is_this_uwu.show(player, form_view, node_name, item_type, mod_name, pointed_thing.under)
		what_is_this_uwu.prev_info_text[pname] = info_text
	end
end

minetest.register_globalstep(function(dtime)
	for _, player in pairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		local hud = what_is_this_uwu.huds[pname]
		hud:on_step(dtime)

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

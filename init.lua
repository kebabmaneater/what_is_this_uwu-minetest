local minetest = minetest
local modpath = minetest.get_modpath("what_is_this_uwu")

dofile(modpath .. "/utils/spring.lua")
dofile(modpath .. "/utils/timer.lua")
dofile(modpath .. "/utils/frame.lua")
dofile(modpath .. "/api.lua")
local what_is_this_uwu = dofile(modpath .. "/help.lua")
local player_hud = dofile(modpath .. "/player_hud.lua")

local store = {
	timers = {},
}

local function show(player)
	local pname = player:get_player_name()
	local pointed_thing, type = what_is_this_uwu.get_pointed_thing(player)

	local hud = what_is_this_uwu.huds[pname]

	if not pointed_thing or not hud then
		what_is_this_uwu.unshow(player)
		return
	end

	if type == "node" then
		hud.looking_at_entity = false
		local node = minetest.get_node(pointed_thing.under)
		local node_name = node.name

		if hud.pointed_thing == node_name then
			return
		end

		local form_view, item_type, node_definition = what_is_this_uwu.get_node_tiles(node_name)
		if not node_definition then
			what_is_this_uwu.unshow(player)
			return
		end

		local mod_name = what_is_this_uwu.split_item_name(node_name)
		what_is_this_uwu.show(player, form_view, node_name, item_type, mod_name, pointed_thing.under)
		hud:show_possible_tools(what_is_this_uwu)

		return
	end

	local mob_name = pointed_thing
	local mod_name = what_is_this_uwu.split_item_name(mob_name)
	hud.looking_at_entity = true
	player:hud_change(hud.best_tool, "text", "")
	player:hud_change(hud.tool_in_hand, "text", "")
	what_is_this_uwu.show_mob(player, mod_name, mob_name, type)
end

local function create_hud(player)
	player:hud_set_flags({ infotext = false })
	local pname = player:get_player_name()

	what_is_this_uwu.huds[pname] = player_hud.new(player)
	local hud = what_is_this_uwu.huds[pname]

	local period = tonumber(minetest.settings:get("what_is_this_uwu_rate_of_change")) or 1.0
	store.timers[pname] = Timer.new(period, function()
		if hud.looking_at_entity then
			player:hud_change(hud.best_tool, "text", "")
			player:hud_change(hud.tool_in_hand, "text", "")
			return
		end
		hud.possible_tool_index = hud.possible_tool_index + 1
		if hud.possible_tool_index > #hud.possible_tools then
			hud.possible_tool_index = 1
		end

		hud:show_possible_tools(what_is_this_uwu)
	end)
end

local function remove_player(player)
	local pname = player:get_player_name()
	what_is_this_uwu.huds[pname] = nil
	store.timers[pname] = nil
end

local function globalstep(dtime)
	for _, player in pairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		local hud = what_is_this_uwu.huds[pname]
		local timer = store.timers[pname]
		if hud and timer then
			hud:on_step(dtime)
			timer:on_step(dtime)
			show(player)
		end
	end
end

minetest.register_on_joinplayer(create_hud)
minetest.register_on_leaveplayer(remove_player)
minetest.register_globalstep(globalstep)
minetest.register_chatcommand("wituwu", {
	params = "",
	description = "Show and unshow the wituwu pop-up",
	privs = {},
	func = function(name)
		what_is_this_uwu.toggle_show(name)
		return true, "Option flipped"
	end,
})

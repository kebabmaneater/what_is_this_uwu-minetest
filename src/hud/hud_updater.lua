local minetest = minetest

local M = {}

function M.init(utils, classes)
	M.utils = utils
	M.classes = classes
end

local function get_translated_desc(utils, desc, lang)
	return utils.string.translate(desc, lang)
end

local function get_info_text(utils, pos, lang)
	if not pos then
		return ""
	end
	local info = WhatIsThisApi.get_info(pos)
	return utils.string.translate(info, lang)
end

local function collect_hud_lines(utils, desc, mod_name, info)
	return utils.string.collect_lines(desc, mod_name, info)
end

local function calculate_hud_size(utils, lines)
	local size = utils.string.max_pixel_width(lines)
	size = utils.settings.apply_text_multiplier(size)
	return size - 18
end

local function calculate_hud_height(utils, info)
	return utils.frame.calculate_hud_height(info)
end

local function update_size(player, node_description, mod_name, node_position, previous_hidden, hud, utils)
	local pname = player:get_player_name()
	local lang = minetest.get_player_information(pname).lang_code

	local desc = get_translated_desc(utils, node_description, lang)
	local info = ""
	if not hud.looking_at_mob and node_position then
		info = get_info_text(utils, node_position, lang)
	end

	local lines = collect_hud_lines(utils, desc, mod_name, info)
	local size = calculate_hud_size(utils, lines)

	local possible_tools = hud:get_possible_tools()
	if #possible_tools == 0 then
		size = size - 20
	end
	local y_size = calculate_hud_height(utils, info)
	hud:size(size, y_size, previous_hidden)
end

local function set_hud_texts(player, hud, desc, mod_name)
	player:hud_change(hud.name, "text", desc)
	player:hud_change(hud.mod, "text", mod_name)
end

local function set_hud_image(player, hud, form_view, item_type, is_mob)
	local mob_scale = { x = 0.3, y = 0.3 }
	local item_scale = { x = 2.5, y = 2.5 }
	local scale = (item_type ~= "node") and item_scale or mob_scale

	if is_mob then
		player:hud_change(hud.image, "scale", mob_scale)
		player:hud_change(hud.image, "text", "wit_ent.png^[resize:146x146")
	else
		player:hud_change(hud.image, "scale", scale)
		player:hud_change(hud.image, "text", form_view)
	end
end

local function show_common(player, hud, desc, mod_name, form_view, item_type, pos, previously_hidden, is_mob, utils)
	update_size(player, desc, mod_name, pos, previously_hidden, hud, utils)
	set_hud_texts(player, hud, desc, mod_name)
	set_hud_image(player, hud, form_view, item_type, is_mob)
end

local function show(player, form_view, node_name, item_type, pos, hud, utils)
	local previously_hidden = false
	if hud.pointed_thing == "ignore" then
		hud:show()
		previously_hidden = true
	end

	if hud.pointed_thing ~= node_name or hud.pointed_thing_pos ~= pos then
		hud:delete_old_lines()
		local additional_info = WhatIsThisApi.get_info(pos)
		hud:parse_additional_info(additional_info or "")
	end

	local mod_name = utils.string.split_item_name(node_name)
	hud.pointed_thing = node_name
	hud.pointed_thing_pos = pos

	local desc = utils.string.get_desc_from_name(node_name, mod_name)
	desc = utils.settings.apply_technical_name(desc, node_name)

	show_common(player, hud, desc, mod_name, form_view, item_type, pos, previously_hidden, false, utils)
	hud.form_view = form_view
end

local function show_mob(player, mob_name, type, form_view, item_type, hud, utils)
	local previously_hidden = false
	if hud.pointed_thing == "ignore" then
		hud:show()
		previously_hidden = true
	end

	hud.pointed_thing = mob_name
	if hud.pointed_thing_pos then
		hud:delete_old_lines()
		hud.pointed_thing_pos = nil
	end

	local mod_name = utils.string.split_item_name(mob_name)
	local num = mob_name:match(" (%d+)$")
	local desc = utils.string.get_desc_from_name(mob_name, mod_name)
	if num and type == "item" then
		desc = num .. " " .. desc
	elseif type == "mob" then
		local name = select(2, utils.string.split_item_name(mob_name))
		mob_name = mob_name:gsub(" %d+$", "")
		desc = utils.string.get_simple_name(name)
	end
	desc = utils.settings.apply_technical_name(desc, mob_name)

	show_common(player, hud, desc, mod_name, form_view, item_type, nil, previously_hidden, type == "mob", utils)
end

local function unshow(hud)
	if not hud then
		return
	end
	hud:hide()
end

function M.update_hud(player, huds, dtime)
	local utils = M.utils
	local pname = player:get_player_name()
	local hud = huds[pname]
	if not hud then
		return
	end

	hud:on_step(dtime)

	if hud.hidden then
		return unshow(hud)
	end

	local pointed_thing, type = utils.entity.get_pointed_thing(player, hud)
	if not pointed_thing then
		return unshow(hud)
	end

	hud.looking_at_entity = type ~= "node"

	local name = "ignore"
	if type == "node" then
		local node = minetest.get_node(pointed_thing.under)
		name = node.name
	else
		name = pointed_thing
	end

	if hud.pointed_thing == name and hud.pointed_thing_pos == pointed_thing.under then
		return
	end

	local form_view, item_type, node_definition = utils.entity.get_node_tiles(name, type)
	if not node_definition and item_type ~= "mob" then
		return unshow(hud)
	end

	if type == "node" then
		show(player, form_view, name, item_type, pointed_thing.under, hud, utils)
		hud:show_possible_tools()
		return
	end

	show_mob(player, name, type, form_view, item_type, hud, utils)
	hud:show_possible_tools({
		hide = true,
	})
end

return M

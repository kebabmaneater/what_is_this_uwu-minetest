local minetest = minetest
local modpath = minetest.get_modpath("what_is_this_uwu")
local entity_utils = dofile(modpath .. "/utils/entity.lua")
local string_utils = dofile(modpath .. "/utils/string.lua")

local string_to_pixels = string_utils.string_to_pixels
local get_simple_name = string_utils.get_simple_name
local get_desc_from_name = string_utils.get_desc_from_name
local split_item_name = string_utils.split_item_name
local get_node_tiles = entity_utils.get_node_tiles

local what_is_this_uwu = {}

local function update_size(player, node_description, mod_name, node_position, previous_hidden, hud)
	local pname = player:get_player_name()
	local lang = minetest.get_player_information(pname).lang_code
	node_description = minetest.get_translated_string(lang, node_description)

	local info = ""
	if not hud.looking_at_mob and node_position then
		info = WhatIsThisApi.get_info(node_position)
		info = minetest.get_translated_string(lang, info)
	end

	local line_contenders = { node_description, mod_name }
	if info and info ~= "" then
		for line in info:gmatch("[^\r\n]+") do
			if line:find("progressbar", 1, true) then
				line = select(3, WhatIsThisApi.parse_string(line))
			end
			table.insert(line_contenders, line)
		end
	end

	local size = 0
	for _, text in ipairs(line_contenders) do
		if text and text ~= "" then
			local s = string_to_pixels(text)
			if s > size then
				size = s
			end
		end
	end

	local mult = tonumber(minetest.settings:get("what_is_this_uwu_text_multiplier"))
	if mult then
		size = math.ceil(size * mult)
	end
	size = size - 18

	local y_size = 3
	if info and info ~= "" then
		y_size = y_size + 1.25 * select(2, info:gsub("\n", "")) + 0.4
	end

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

local function apply_itemname_setting(desc, name)
	local tech = minetest.settings:get_bool("what_is_this_uwu_itemname", false)
	if tech and desc ~= "" then
		return desc .. " [" .. name .. "]"
	end
	return desc
end

local function show_common(player, hud, desc, mod_name, form_view, item_type, pos, previously_hidden, is_mob)
	update_size(player, desc, mod_name, pos, previously_hidden, hud)
	set_hud_texts(player, hud, desc, mod_name)
	set_hud_image(player, hud, form_view, item_type, is_mob)
end

local function show(player, form_view, node_name, item_type, pos, hud)
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

	local mod_name = split_item_name(node_name)
	hud.pointed_thing = node_name
	hud.pointed_thing_pos = pos

	local desc = get_desc_from_name(node_name, mod_name)
	desc = apply_itemname_setting(desc, node_name)

	show_common(player, hud, desc, mod_name, form_view, item_type, pos, previously_hidden, false)
	hud.form_view = form_view
end

local function show_mob(player, mob_name, type, form_view, item_type, hud)
	local previously_hidden = false
	if hud.pointed_thing == "ignore" then
		hud:show()
		previously_hidden = true
	end

	hud.pointed_thing = mob_name
	if hud.pointed_thing_pos ~= nil then
		hud:delete_old_lines()
		hud.pointed_thing_pos = nil
	end

	local mod_name = split_item_name(mob_name)
	local num = mob_name:match(" (%d+)$")
	local desc = get_desc_from_name(mob_name, mod_name)
	if num and type == "item" then
		desc = num .. " " .. desc
	elseif type == "mob" then
		local name = select(2, split_item_name(mob_name))
		mob_name = mob_name:gsub(" %d+$", "") --remove number from end
		desc = get_simple_name(name)
	end
	desc = apply_itemname_setting(desc, mob_name)

	show_common(player, hud, desc, mod_name, form_view, item_type, nil, previously_hidden, type == "mob")
end

local function unshow(hud)
	if not hud then
		return
	end
	hud:hide()
end

function what_is_this_uwu.update_hud(player, huds)
	local pname = player:get_player_name()
	local hud = huds[pname]
	if not hud then
		return
	end

	if hud.hidden then
		return unshow(hud)
	end

	local pointed_thing, type = entity_utils.get_pointed_thing(player, hud)
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

	local form_view, item_type, node_definition = get_node_tiles(name, type)
	if not node_definition and item_type ~= "mob" then
		return unshow(hud)
	end

	if type == "node" then
		show(player, form_view, name, item_type, pointed_thing.under, hud)
		hud:show_possible_tools()
	else
		show_mob(player, name, type, form_view, item_type, hud)
		hud:show_possible_tools({
			hide = true,
		})
	end
end

return what_is_this_uwu

local what_is_this_uwu = {
	huds = {},
}

local CHAR_WIDTHS = {
	A = 12,
	B = 10,
	C = 13,
	D = 12,
	E = 11,
	F = 9,
	G = 13,
	H = 12,
	I = 3,
	J = 9,
	K = 11,
	L = 9,
	M = 13,
	N = 11,
	O = 13,
	P = 10,
	Q = 13,
	R = 12,
	S = 10,
	T = 11,
	U = 11,
	V = 10,
	W = 15,
	X = 11,
	Y = 11,
	Z = 10,
	a = 10,
	b = 8,
	c = 8,
	d = 9,
	e = 9,
	f = 5,
	g = 9,
	h = 9,
	i = 2,
	j = 6,
	k = 8,
	l = 4,
	m = 13,
	n = 8,
	o = 10,
	p = 8,
	q = 10,
	r = 4,
	s = 8,
	t = 5,
	u = 8,
	v = 8,
	w = 12,
	x = 8,
	y = 8,
	z = 8,
	[" "] = 5,
	["("] = 5,
	[")"] = 5,
	["["] = 5,
	["]"] = 5,
	["_"] = 9,
	["1"] = 9,
	["2"] = 9,
	["3"] = 9,
	["4"] = 9,
	["5"] = 9,
	["6"] = 9,
	["7"] = 9,
	["8"] = 9,
	["9"] = 9,
	["0"] = 9,
	["."] = 3,
	[","] = 3,
	["/"] = 8,
	[":"] = 3,
}

local DEFAULT_CHAR_WIDTH = 14

local function string_to_pixels(str)
	local size = 0
	for i = 1, #str do
		local char = str:sub(i, i)
		size = size + (CHAR_WIDTHS[char] or DEFAULT_CHAR_WIDTH)
	end
	return size
end

local function inventorycube(img1, img2, img3)
	if not img1 then
		return ""
	end
	local images = {
		(img1 .. "^[resize:16x16"):gsub("%^", "&"),
		(img2 .. "^[resize:16x16"):gsub("%^", "&"),
		(img3 .. "^[resize:16x16"):gsub("%^", "&"),
	}
	return "[inventorycube{" .. table.concat(images, "{")
end

function what_is_this_uwu.split_item_name(item_name)
	local colon_pos = item_name:find(":")
	if colon_pos then
		return item_name:sub(1, colon_pos - 1), item_name:sub(colon_pos + 1)
	end
	return item_name, ""
end

function what_is_this_uwu.toggle_show(name)
	local hud = what_is_this_uwu.huds[name]
	hud.hidden = not hud.hidden
	what_is_this_uwu.unshow(minetest.get_player_by_name(name))
end

local function process_entity(entity, playerName)
	if not entity then
		return nil
	end
	if entity.type == "node" then
		return entity, "node"
	end
	local mob = entity.ref and entity.ref:get_luaentity()
	if mob and mob.name ~= playerName then
		local mob_name = mob.name or mob.type
		if mob_name and mob_name:find("__builtin") then
			return mob.itemstring, "item"
		end
		return mob_name, "mob"
	end
	return nil
end

function what_is_this_uwu.get_pointed_thing(player)
	local pname = player:get_player_name()
	local hud = what_is_this_uwu.huds[pname]
	if hud.hidden then
		return
	end

	local player_props = player:get_properties()
	local player_pos = player:get_pos() + vector.new(0, player_props.eye_height, 0) + player:get_eye_offset()
	local look_dir = player:get_look_dir()

	local node_name = minetest.get_node(player_pos).name
	local see_liquid = minetest.registered_nodes[node_name].drawtype ~= "liquid"

	local wielded_item = player:get_wielded_item()
	local tool_range = wielded_item:get_definition().range or minetest.registered_items[""].range or 5
	local end_pos = player_pos + look_dir * tool_range

	for i = 1, 5 do
		local start_pos = player_pos + look_dir * (i / 3)
		local entity = minetest.raycast(start_pos, end_pos, true, see_liquid):next()
		local result, kind = process_entity(entity, pname)
		if result then
			return result, kind
		end
	end

	return nil, nil
end

function what_is_this_uwu.get_node_tiles(node_name, node_thing_type)
	if node_thing_type == "mob" then
		return "wit_end.png", "craft_item", true
	elseif node_thing_type == "item" then
		node_name = node_name:gsub(" %d+$", "")
	end

	local node = minetest.registered_items[node_name] or minetest.registered_nodes[node_name]
	if not node or (not node.tiles and not node.inventory_image) then
		return "ignore", "node", false
	end

	local initial_node = node

	if node.groups and node.groups["not_in_creative_inventory"] then
		local drop = node.drop
		if drop and type(drop) == "string" then
			local drop_node = minetest.registered_nodes[drop] or minetest.registered_craftitems[drop]
			if drop_node then
				node = drop_node
				node_name = drop
			end
		elseif node_name:find("_active") then
			local base_name = node_name:gsub("_active", "")
			local base_node = minetest.registered_nodes[base_name]
			if base_node then
				node = base_node
				node_name = base_name
			end
		end

		if not node or (not node.tiles and not node.inventory_image) then
			node = initial_node
		end
	end

	if not node or (not node.tiles and not node.inventory_image) then
		return "ignore", "node", false
	end

	local inventory_image = node.inventory_image or ""
	if inventory_image:sub(1, 14) == "[inventorycube" then
		return inventory_image .. "^[resize:146x146", "node", node
	elseif inventory_image ~= "" then
		return inventory_image .. "^[resize:16x16", "craft_item", node
	end

	local tiles = node.tiles
	if tiles then
		local tile1 = tiles[1] or tiles[1]
		local tile3 = tiles[3] or tile1
		local tile6 = tiles[6] or tile3

		if type(tile1) == "table" then
			tile1 = tile1.name
		end
		if type(tile3) == "table" then
			tile3 = tile3.name
		end
		if type(tile6) == "table" then
			tile6 = tile6.name
		end

		return inventorycube(tile1, tile6, tile3), "node", node
	end
end

local function show_background(player)
	local name = player:get_player_name()
	local hud = what_is_this_uwu.huds[name]
	hud:show()
end

local function update_size(player, node_description, mod_name, node_position, previous_hidden)
	local pname = player:get_player_name()
	local hud = what_is_this_uwu.huds[pname]
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

local function get_first_line(text)
	local firstnewline = text:find("\n")
	return firstnewline and text:sub(1, firstnewline - 1) or text
end

local function get_desc_from_name(node_name, mod_name)
	local wstack = ItemStack(node_name)
	local def = minetest.registered_items[node_name]

	local desc
	if wstack.get_short_description then
		desc = wstack:get_short_description()
	end
	if (not desc or desc == "") and wstack.get_description then
		desc = wstack:get_description()
	end
	if (not desc or desc == "") and not wstack.get_description then
		local meta = wstack:get_meta()
		desc = meta:get_string("description")
	end
	if not desc or desc == "" then
		desc = def.description
	end
	if not desc or desc == "" then
		desc = node_name
	end
	desc = get_first_line(desc)

	if mod_name == "pipeworks" then
		desc = desc:gsub("%{$", "")
	end

	return desc
end

function what_is_this_uwu.show(player, form_view, node_name, item_type, mod_name, pos)
	local name = player:get_player_name()
	local hud = what_is_this_uwu.huds[name]

	local previously_hidden = false
	if hud.pointed_thing == "ignore" then
		show_background(player)
		previously_hidden = true
	end

	if hud.pointed_thing ~= node_name then
		hud:delete_old_lines()
		local additional_info = WhatIsThisApi.get_info(pos)
		hud:parse_additional_info(additional_info or "")
	end

	hud.pointed_thing = node_name
	hud.pointed_thing_pos = pos

	local desc = get_desc_from_name(node_name, mod_name)
	local tech = minetest.settings:get_bool("what_is_this_uwu_itemname", false)
	if tech and desc ~= "" then
		desc = desc .. " [" .. node_name .. "]"
	end

	update_size(player, desc, mod_name, pos, previously_hidden)

	player:hud_change(hud.name, "text", desc)
	player:hud_change(hud.mod, "text", mod_name)

	local scale = { x = 0.3, y = 0.3 }
	if item_type ~= "node" then
		scale = { x = 2.5, y = 2.5 }
	end

	player:hud_change(hud.image, "scale", scale)
	player:hud_change(hud.image, "text", form_view)
	hud.form_view = form_view
end

function what_is_this_uwu.get_simple_name(full_name)
	local name = full_name:match("^[^:]+:(.+)$") or full_name
	name = name:gsub("_", " ")
	return name:sub(1, 1):upper() .. name:sub(2)
end

function what_is_this_uwu.show_mob(player, mod_name, mob_name, type, form_view, item_type)
	local pname = player:get_player_name()
	local hud = what_is_this_uwu.huds[pname]

	local previously_hidden = false
	if hud.pointed_thing == "ignore" then
		show_background(player)
		previously_hidden = true
	end

	hud.pointed_thing = mob_name
	if hud.pointed_thing_pos ~= nil then
		hud:delete_old_lines()
		hud.pointed_thing_pos = nil
	end

	local num = mob_name:match(" (%d+)$")
	local desc = get_desc_from_name(mob_name, mod_name)
	if num and type == "item" then
		desc = num .. " " .. desc
		update_size(player, desc, mod_name, nil, previously_hidden)
	elseif type == "mob" then
		local simple_name = what_is_this_uwu.get_simple_name(mob_name)
		desc = simple_name
	end

	local tech = minetest.settings:get_bool("what_is_this_uwu_itemname", false)
	if tech and desc ~= "" then
		desc = desc .. " [" .. mob_name .. "]"
	end

	update_size(player, desc, mod_name, nil, previously_hidden)
	player:hud_change(hud.name, "text", desc)
	player:hud_change(hud.mod, "text", mod_name)

	if type == "item" then
		mob_name = mob_name:gsub(" %d+$", "")
		local scale = { x = 0.3, y = 0.3 }
		if item_type ~= "node" then
			scale = { x = 2.5, y = 2.5 }
		end
		player:hud_change(hud.image, "scale", scale)
		player:hud_change(hud.image, "text", form_view)
	else
		player:hud_change(hud.image, "scale", { x = 0.3, y = 0.3 })
		player:hud_change(hud.image, "text", "wit_ent.png^[resize:146x146")
	end
end

function what_is_this_uwu.unshow(player)
	if not player then
		return
	end
	local name = player:get_player_name()
	local hud = what_is_this_uwu.huds[name]
	if not hud then
		return
	end
	hud:hide()
end

return what_is_this_uwu

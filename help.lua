local what_is_this_uwu = {
	players = {},
	players_set = {},
	prev_tool = {},
}

local char_width = {
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
	["_"] = 9,
}

local function string_to_pixels(str)
	local size = 0
	for char in str:gmatch(".") do
		size = size + (char_width[char] or 14)
	end
	local mult = minetest.settings:get("what_is_this_uwu_text_multiplier", 1.0)
	if mult then
		size = math.ceil(size * mult)
	end

	return size
end

local function inventorycube(img1, img2, img3)
	if not img1 then
		return ""
	end

	local images = { img1, img2, img3 }
	for i = 1, 3 do
		images[i] = images[i] .. "^[resize:16x16"
		images[i] = images[i]:gsub("%^", "&")
	end

	return "[inventorycube{" .. table.concat(images, "{")
end

function what_is_this_uwu.split_item_name(item_name)
	local splited = {}
	for char in item_name:gmatch("[^:]+") do
		table.insert(splited, char)
	end
	return splited[1], splited[2]
end

function what_is_this_uwu.register_player(player, name)
	if what_is_this_uwu.players_set[name] then
		return
	end

	table.insert(what_is_this_uwu.players, player)
	what_is_this_uwu.players_set[name] = true
end

function what_is_this_uwu.remove_player(name)
	if not what_is_this_uwu.players_set[name] then
		return
	end

	what_is_this_uwu.players_set[name] = false

	for i, player in ipairs(what_is_this_uwu.players) do
		if player == name then
			table.remove(what_is_this_uwu.players, i)
			break
		end
	end
end

function what_is_this_uwu.get_pointed_thing(player)
	local playerName = player:get_player_name()
	if not what_is_this_uwu.players_set[playerName] then
		return
	end

	local player_pos = player:get_pos() + vector.new(0, player:get_properties().eye_height, 0) + player:get_eye_offset()

	local node_name = minetest.get_node(player_pos).name
	local see_liquid = minetest.registered_nodes[node_name].drawtype ~= "liquid"

	local tool_range = player:get_wielded_item():get_definition().range or minetest.registered_items[""].range or 5
	local end_pos = player_pos + player:get_look_dir() * tool_range

	local ray = minetest.raycast(player_pos, end_pos, false, see_liquid)
	return ray:next()
end

function what_is_this_uwu.get_node_tiles(node_name)
	local node = minetest.registered_nodes[node_name]
	if node == nil or (not node.tiles and not node.inventory_image) then
		return "ignore", "node", false
	end

	if node.groups["not_in_creative_inventory"] then
		drop = node.drop
		if drop and type(drop) == "string" then
			node_name = drop
			node = minetest.registered_nodes[drop]
			if not node then
				node = minetest.registered_craftitems[drop]
			end
		end
	end

	if not node or (not node.tiles and not node.inventory_image) then
		return "ignore", "node", false
	end

	local tiles = node.tiles or {}

	if node.inventory_image:sub(1, 14) == "[inventorycube" then
		return node.inventory_image .. "^[resize:146x146", "node", node
	elseif node.inventory_image ~= "" then
		return node.inventory_image .. "^[resize:16x16", "craft_item", node
	elseif tiles then
		tiles[3] = tiles[3] or tiles[1]
		tiles[6] = tiles[6] or tiles[3]

		if type(tiles[1]) == "table" then
			tiles[1] = tiles[1].name
		end
		if type(tiles[3]) == "table" then
			tiles[3] = tiles[3].name
		end
		if type(tiles[6]) == "table" then
			tiles[6] = tiles[6].name
		end

		return inventorycube(tiles[1], tiles[6], tiles[3]), "node", node
	end
end

function what_is_this_uwu.show_background(player, meta)
	player:hud_change(meta:get_string("wit:background_left"), "text", "wit_left_side.png")
	player:hud_change(meta:get_string("wit:background_middle"), "text", "wit_middle.png")
	player:hud_change(meta:get_string("wit:background_right"), "text", "wit_right_side.png")
end

local function update_size(...)
	local player, meta, form_view, node_description, node_name, item_type, mod_name = ...
	local size
	node_description =
		core.get_translated_string(core.get_player_information(player:get_player_name()).lang_code, node_description)

	local tech = minetest.settings:get_bool("what_is_this_uwu_itemname", false)
	if tech and node_description ~= "" then
		node_description = node_description .. " [" .. node_name .. "]"
	end

	if #node_description >= #mod_name then
		size = string_to_pixels(node_description) - 18
	else
		size = string_to_pixels(mod_name) - 18
	end

	if tech then
		size = size - 32 --Haphazard fix, but eh
	end

	player:hud_change(meta:get_string("wit:background_middle"), "scale", { x = size / 16 + 1.5, y = 2 })
	player:hud_change(meta:get_string("wit:background_middle"), "offset", { x = -size / 2 - 9.5, y = 35 })
	player:hud_change(meta:get_string("wit:background_right"), "offset", { x = size / 2 + 30, y = 35 })
	player:hud_change(meta:get_string("wit:background_left"), "offset", { x = -size / 2 - 25, y = 35 })
	player:hud_change(meta:get_string("wit:image"), "offset", { x = -size / 2 - 12.5, y = 35 })
	player:hud_change(meta:get_string("wit:name"), "offset", { x = -size / 2 + 16.5, y = 22 })
	player:hud_change(meta:get_string("wit:mod"), "offset", { x = -size / 2 + 16.5, y = 37 })
	player:hud_change(meta:get_string("wit:best_tool"), "offset", { x = -size / 2 + 16.5, y = 51 })
	player:hud_change(meta:get_string("wit:tool_in_hand"), "offset", { x = -size / 2 + 16.5, y = 51 })
end

local function show_best_tool(player, meta, form_view, node_description, node_name, item_type, mod_name)
	local index_to_image = {
		"wit_hand.png",
		"wit_spade.png",
		"wit_pickaxe.png",
		"wit_hand.png",
		"wit_axe.png",
		"wit_sword.png",
		"wit_hand.png",
	}

	local tool_group_names = { "pickaxe", "shovel", "sword", "axe" }
	local group_index = -1

	local item_def = minetest.registered_items[node_name]
	local groups = item_def.groups

	for index, group in ipairs({ "dig_immediate", "crumbly", "cracky", "snappy", "choppy", "fleshy", "explody" }) do
		if groups[group] then
			group_index = index
			break
		end
	end

	local best_to_mine = index_to_image[group_index] or "wit_hand.png"

	local wielded_item = player:get_wielded_item()
	local item_name = wielded_item:get_name()

	local correct_tool_in_hand = false
	local liquids = { "default:water_source", "default:river_water_source", "default:lava_source" }
	if table.concat(liquids, ","):find(node_name) then
		best_to_mine = "wit_bucket.png"
		correct_tool_in_hand = (item_name == "bucket:bucket_empty")
	else
		local show_hand = true

		for _, tool_group in ipairs(tool_group_names) do
			if minetest.get_item_group(item_name, tool_group) > 0 then
				correct_tool_in_hand = (group_index == ({ 3, 2, 6, 5 })[_])
				show_hand = false
				break
			end
		end

		if (group_index ~= 3 and group_index ~= 2 and group_index ~= 6 and group_index ~= 5) and show_hand then
			correct_tool_in_hand = true
		end
	end

	player:hud_change(meta:get_string("wit:best_tool"), "text", best_to_mine)
	player:hud_change(
		meta:get_string("wit:tool_in_hand"),
		"text",
		correct_tool_in_hand and "wit_checkmark.png" or "wit_nope.png"
	)
	player:hud_change(meta:get_string("wit:image"), "text", form_view)
end

local function get_first_line(text)
	-- Cut off text after first newline
	local firstnewline = string.find(text, "\n")
	if firstnewline then
		text = string.sub(text, 1, firstnewline - 1)
	end
	return text
end

function what_is_this_uwu.show(player, meta, form_view, node_name, item_type, mod_name)
	if meta:get_string("wit:pointed_thing") == "ignore" then
		what_is_this_uwu.show_background(player, meta)
	end

	meta:set_string("wit:pointed_thing", node_name)

	local wstack = ItemStack(node_name)
	local def = minetest.registered_items[node_name]
	local desc
	if wstack.get_short_description then
		-- get_short_description()
		desc = wstack:get_short_description()
	end
	if (not desc or desc == "") and wstack.get_description then
		-- get_description()
		desc = wstack:get_description()
		desc = get_first_line(desc)
	end
	if (not desc or desc == "") and not wstack.get_description then
		-- Metadata (old versions only)
		local meta = wstack:get_meta()
		desc = meta:get_string("description")
		desc = get_first_line(desc)
	end
	if not desc or desc == "" then
		-- Item definition
		desc = def.description
		desc = get_first_line(desc)
	end
	if not desc or desc == "" then
		-- Final fallback: itemstring
		desc = node_name
	end

	update_size(player, meta, form_view, desc, node_name, item_type, mod_name)
	show_best_tool(player, meta, form_view, desc, node_name, item_type, mod_name)

	local tech = minetest.settings:get_bool("what_is_this_uwu_itemname", false)
	if tech and desc ~= "" then
		desc = desc .. " [" .. node_name .. "]"
	end
	player:hud_change(meta:get_string("wit:name"), "text", desc)
	player:hud_change(meta:get_string("wit:mod"), "text", mod_name)

	local scale = { x = 0.3, y = 0.3 }
	if item_type ~= "node" then
		scale = { x = 2.5, y = 2.5 }
	end

	meta:set_string("wit:item_type_in_pointer", item_type)
	player:hud_change(meta:get_string("wit:image"), "scale", scale)
end

function what_is_this_uwu.unshow(player, meta)
	if not meta then
		return
	end
	meta:set_string("wit:pointed_thing", "ignore")

	local hud_elements = {
		"wit:background_left",
		"wit:background_middle",
		"wit:background_right",
		"wit:image",
		"wit:name",
		"wit:mod",
		"wit:best_tool",
		"wit:tool_in_hand",
	}

	for _, element in ipairs(hud_elements) do
		player:hud_change(meta:get_string(element), "text", "")
	end
end

return what_is_this_uwu

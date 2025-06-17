local what_is_this_uwu = {
	prev_tool = {},
	huds = {},
	possible_tools = {},
	possible_tool_index = {},
	dtimes = {},
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

function what_is_this_uwu.toggle_show(name)
	local hud = what_is_this_uwu.huds[name]
	hud.hidden = not hud.hidden
	what_is_this_uwu.unshow(minetest.get_player_by_name(name))
end

function what_is_this_uwu.get_pointed_thing(player)
	local playerName = player:get_player_name()
	local hud = what_is_this_uwu.huds[playerName]
	if hud.hidden == true then
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

	local initial_node = node
	if node.groups["not_in_creative_inventory"] then
		local drop = node.drop
		if drop and type(drop) == "string" then
			node_name = drop
			node = minetest.registered_nodes[drop]
			if not node then
				node = minetest.registered_craftitems[drop]
			end
			if not node then
				node = initial_node
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

function what_is_this_uwu.show_background(player)
	local name = player:get_player_name()
	local hud = what_is_this_uwu.huds[name]
	hud:show()
end

local function update_size(...)
	local player, node_description, node_name, mod_name = ...
	local size
	node_description =
		core.get_translated_string(core.get_player_information(player:get_player_name()).lang_code, node_description)

	local tech = minetest.settings:get_bool("what_is_this_uwu_itemname", false)
	if tech and node_description ~= "" then
		node_description = node_description .. " [" .. node_name .. "]"
	end

	local str = (#node_description >= #mod_name) and node_description or mod_name
	size = string_to_pixels(str)

	local mult = minetest.settings:get("what_is_this_uwu_text_multiplier", 1.0)
	if mult then
		size = math.ceil(size * mult)
	end

	if size % 2 ~= 0 then
		size = size + 1 -- Make sure size is even
	end

	size = size - 18
	if tech then
		size = size - 32 --Haphazard fix, but eh
	end

	local hud = what_is_this_uwu.huds[player:get_player_name()]
	hud:size(size)
end

local function show_best_tool(player, form_view, node_name)
	local name = player:get_player_name()
	local item_def = minetest.registered_items[node_name]
	local groups = item_def.groups

	what_is_this_uwu.possible_tools[name] = {}
	for toolname, tooldef in pairs(minetest.registered_tools) do
		if tooldef.tool_capabilities then
			for group, _ in pairs(groups) do
				if tooldef.tool_capabilities.groupcaps then
					if tooldef.tool_capabilities.groupcaps[group] then
						table.insert(what_is_this_uwu.possible_tools[name], toolname)
					end
				end
			end
		end
	end

	local wielded_item = player:get_wielded_item()
	local item_name = wielded_item:get_name()

	local correct_tool_in_hand = false
	local liquids = { "default:water_source", "default:river_water_source", "default:lava_source" }
	if table.concat(liquids, ","):find(node_name) then
		what_is_this_uwu.possible_tools[name] = { "bucket:bucket_empty" }
		correct_tool_in_hand = (item_name == "bucket:bucket_empty")
	else
		for _, tool in ipairs(what_is_this_uwu.possible_tools[name]) do
			if item_name == tool then
				correct_tool_in_hand = true
				break
			end
		end
	end

	local tool = what_is_this_uwu.possible_tools[name][what_is_this_uwu.possible_tool_index[name]]
	if tool == nil then
		tool = what_is_this_uwu.possible_tools[name][1]
	end
	local texture = ""
	if minetest.registered_tools[tool] then
		if minetest.registered_tools[tool].inventory_image then
			texture = minetest.registered_tools[tool].inventory_image
		end
	end
	if texture == "" and minetest.registered_craftitems[tool] then
		if minetest.registered_craftitems[tool].inventory_image then
			texture = minetest.registered_craftitems[tool].inventory_image
		end
	end

	player:hud_change(what_is_this_uwu.huds[name].best_tool, "text", texture)
	if texture == "" then
		player:hud_change(what_is_this_uwu.huds[name].tool_in_hand, "text", "")
	else
		player:hud_change(
			what_is_this_uwu.huds[name].tool_in_hand,
			"text",
			correct_tool_in_hand and "wit_checkmark.png" or "wit_nope.png"
		)
	end
	player:hud_change(what_is_this_uwu.huds[name].image, "text", form_view)
end

local function get_first_line(text)
	local firstnewline = string.find(text, "\n")
	if firstnewline then
		text = string.sub(text, 1, firstnewline - 1)
	end
	return text
end

local function get_desc_from_name(node_name)
	local wstack = ItemStack(node_name)
	local def = minetest.registered_items[node_name]

	local desc
	if wstack.get_short_description then
		desc = wstack:get_short_description()
	end
	if (not desc or desc == "") and wstack.get_description then
		desc = wstack:get_description()
		desc = get_first_line(desc)
	end
	if (not desc or desc == "") and not wstack.get_description then
		local meta = wstack:get_meta()
		desc = meta:get_string("description")
		desc = get_first_line(desc)
	end
	if not desc or desc == "" then
		desc = def.description
		desc = get_first_line(desc)
	end
	if not desc or desc == "" then
		desc = node_name
	end
	return desc
end

function what_is_this_uwu.show(player, form_view, node_name, item_type, mod_name, pos)
	local name = player:get_player_name()
	if what_is_this_uwu.huds[name].pointed_thing == "ignore" then
		what_is_this_uwu.show_background(player)
	end

	what_is_this_uwu.huds[name].pointed_thing = node_name

	local desc = get_desc_from_name(node_name, pos)

	update_size(player, desc, node_name, mod_name)
	show_best_tool(player, form_view, node_name)

	local tech = minetest.settings:get_bool("what_is_this_uwu_itemname", false)
	if tech and desc ~= "" then
		desc = desc .. " [" .. node_name .. "]"
	end
	player:hud_change(what_is_this_uwu.huds[name].name, "text", desc)
	player:hud_change(what_is_this_uwu.huds[name].mod, "text", mod_name)

	local scale = { x = 0.3, y = 0.3 }
	if item_type ~= "node" then
		scale = { x = 2.5, y = 2.5 }
	end

	player:hud_change(what_is_this_uwu.huds[name].image, "scale", scale)
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

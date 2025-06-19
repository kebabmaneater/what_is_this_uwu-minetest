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

local function string_to_pixels(str)
	local size = 0
	for char in str:gmatch(".") do
		size = size + (CHAR_WIDTHS[char] or 14)
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
	local splits = {}
	for char in item_name:gmatch("[^:]+") do
		table.insert(splits, char)
	end
	return splits[1], splits[2]
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

	-- this code is shit but it works
	local return_thing, type = nil, nil
	for i = 1, 5 do
		local entity = minetest.raycast(player_pos + player:get_look_dir() * i, end_pos, true, see_liquid):next()
		if entity then
			if entity.type ~= "node" then
				local mob = entity.ref and entity.ref:get_luaentity()
				if mob and mob.name ~= player:get_player_name() then
					return_thing = mob.name or mob.type
					type = "mob"
					if return_thing:find("__builtin") then
						return_thing = mob.itemstring
						type = "item"
					end
					break
				end
			else
				return_thing = entity
				type = "node"
				break
			end
		end
	end

	return return_thing, type
end

function what_is_this_uwu.get_node_tiles(node_name, node_thing_type)
	if node_thing_type == "mob" then
		return "wit_end.png", "craft_item", true
	elseif node_thing_type == "item" then
		node_name = node_name:gsub(" %d+$", "") --remove number from end
	end
	local node = minetest.registered_items[node_name] or minetest.registered_nodes[node_name]
	if node == nil or (not node.tiles and not node.inventory_image) then
		return "ignore", "node", false
	end

	local initial_node = node
	if node.groups["not_in_creative_inventory"] then
		local drop = node.drop
		local drop_found = false
		if drop and type(drop) == "string" then
			node_name = drop
			node = minetest.registered_nodes[drop]
			if not node then
				node = minetest.registered_craftitems[drop]
				if node then
					drop_found = true
				end
			end
		end
		if not drop_found and node_name:find("_active") ~= nil then
			node_name = node_name:gsub("_active", "")
			node = minetest.registered_nodes[node_name]
		end
		if not node then
			node = initial_node
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
	local player, node_description, mod_name, node_position, previous_hidden = ...
	local size
	node_description = minetest.get_translated_string(
		minetest.get_player_information(player:get_player_name()).lang_code,
		node_description
	)

	local hud = what_is_this_uwu.huds[player:get_player_name()]

	local longest = ""
	local what_is_this_info = ""
	if not hud.looking_at_mob and node_position ~= nil then
		what_is_this_info = WhatIsThisApi.get_info(node_position)
		what_is_this_info = minetest.get_translated_string(
			minetest.get_player_information(player:get_player_name()).lang_code,
			what_is_this_info
		)
		if what_is_this_info and what_is_this_info ~= nil then
			local lines = {}
			for line in what_is_this_info:gmatch("[^\r\n]+") do
				-- if progress bar, get the text part
				if line:match("progressbar") ~= nil then
					line = select(3, WhatIsThisApi.parse_string(line))
				end
				table.insert(lines, line)
			end
			for _, line in ipairs(lines) do
				if #line > #longest then
					longest = line
				end
			end
		end
	end

	local size_contenders = { longest, node_description, mod_name }
	local biggest_index = 0
	for index, contender in ipairs(size_contenders) do
		if contender ~= nil and contender ~= "" then
			local contender_size = string_to_pixels(contender)
			if not size or contender_size > size then
				biggest_index = index
				size = contender_size
			end
		end
	end

	if biggest_index == 1 then
		size = size * 0.9 -- It gets inflated for no reason!
	end

	local mult = minetest.settings:get("what_is_this_uwu_text_multiplier")
	mult = tonumber(mult)
	if type(mult) == "number" then
		size = math.ceil(size * mult)
	end

	if size % 2 ~= 0 then
		size = size + 1 -- Make sure size is even
	end

	size = size - 18

	local y_size = 3

	if what_is_this_info and what_is_this_info ~= "" then
		for _ in what_is_this_info:gmatch("\n") do
			y_size = y_size + 1.25
		end

		y_size = y_size + 0.4 -- Add one for the one line without a newline
	end

	hud:size(size, y_size, previous_hidden)
end

local function get_first_line(text)
	local firstnewline = string.find(text, "\n")
	if firstnewline then
		text = string.sub(text, 1, firstnewline - 1)
	end
	return text
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
		desc = desc:gsub("%{$", "") --very hacky fix for pipeworks
	end

	return desc
end

function what_is_this_uwu.show(player, form_view, node_name, item_type, mod_name, pos)
	local name = player:get_player_name()
	local hud = what_is_this_uwu.huds[name]

	local previously_hidden = false
	if hud.pointed_thing == "ignore" then
		what_is_this_uwu.show_background(player)
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
		what_is_this_uwu.show_background(player)
		previously_hidden = true
	end

	hud.pointed_thing = mob_name

	--get the number from item end if it exists
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
		mob_name = mob_name:gsub(" %d+$", "") --remove number from end
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

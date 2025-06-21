local entity_utils = {}

function entity_utils.inventorycube(img1, img2, img3)
	if not img1 or not img2 or not img3 then
		return ""
	end
	local images = {
		(img1 .. "^[resize:16x16"):gsub("%^", "&"),
		(img2 .. "^[resize:16x16"):gsub("%^", "&"),
		(img3 .. "^[resize:16x16"):gsub("%^", "&"),
	}
	return "[inventorycube{" .. table.concat(images, "{")
end

function entity_utils.get_node_tiles(node_name, node_thing_type)
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

	if node.groups and node.groups.not_in_creative_inventory then
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

		return entity_utils.inventorycube(tile1, tile6, tile3), "node", node
	end
end

function entity_utils.process_entity(entity, playerName)
	if not entity then
		return nil
	end
	if entity.type == "node" then
		return entity, "node"
	end
	local mob = entity.ref and entity.ref:get_luaentity()
	if mob and mob.name ~= playerName then
		local mob_name = mob.name or mob.type
		if mob_name and mob_name:find("drawers") then
			return nil, "drawer_visual"
		end
		if mob_name and mob_name:find("__builtin") then
			return mob.itemstring, "item"
		end
		return mob_name, "mob"
	end
	return nil, "nothing"
end

function entity_utils.get_pointed_thing(player)
	local pname = player:get_player_name()
	local player_props = player:get_properties()
	local player_pos = player:get_pos() + vector.new(0, player_props.eye_height, 0) + player:get_eye_offset()
	local look_dir = player:get_look_dir()

	local node_name = minetest.get_node(player_pos).name
	local see_liquid = minetest.registered_nodes[node_name].drawtype ~= "liquid"

	local wielded_item = player:get_wielded_item()
	local tool_range = wielded_item:get_definition().range or minetest.registered_items[""].range or 5
	local end_pos = player_pos + look_dir * tool_range

	local MAX_TIMES = 10
	for i = 1, MAX_TIMES do
		local start_pos = player_pos + look_dir * tool_range * (i / MAX_TIMES)
		local entity = minetest.raycast(start_pos, end_pos, true, see_liquid):next()
		local result, kind = entity_utils.process_entity(entity, pname)
		if result then
			return result, kind
		end
	end

	return nil, nil
end

return entity_utils

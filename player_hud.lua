local player_hud = {}
player_hud.__index = player_hud

local hud_type_field_name = minetest.features.hud_def_type_field and "type" or "hud_elem_type"
local minetest = minetest
local modpath = minetest.get_modpath("what_is_this_uwu")
dofile(modpath .. "/utils/spring.lua")
dofile(modpath .. "/utils/timer.lua")
dofile(modpath .. "/utils/frame.lua")

local function get_vec2(tbl, default_x, default_y)
	default_x = default_x or 0
	default_y = default_y or 0
	return { x = (tbl and tbl.x) or default_x, y = (tbl and tbl.y) or default_y }
end

function player_hud.new(player, data)
	local self = setmetatable({}, player_hud)

	data = data or {}
	local alignment = get_vec2(data.alignment, 0, 1)
	local position = get_vec2(data.position, 0.5, 0)
	local offset = get_vec2(data.offset, 0, 10)
	self.alignment = alignment
	self.position = position
	self.offset = offset

	self.player = player
	self.hidden = false
	self.shown_on_screen = true
	self.frame = Slice9Frame.new({
		side = "wit_side.png",
		center = "wit_center.png",
		edge = "wit_edge.png",
		position = position,
		alignment = alignment,
		offset = offset,
		player = player,
	})

	self.image = player:hud_add({
		[hud_type_field_name] = "image",
		position = position,
		alignment = { x = 1 },
		scale = { x = 0.3, y = 0.3 },
	})
	self.name = player:hud_add({
		[hud_type_field_name] = "text",
		position = position,
		scale = { x = 0.3, y = 0.3 },
		number = 0xffffff,
		alignment = { x = 1 },
	})
	self.mod = player:hud_add({
		[hud_type_field_name] = "text",
		position = position,
		scale = { x = 0.3, y = 0.3 },
		number = 0xff3c0a,
		alignment = { x = 1 },
		style = 2,
	})
	self.best_tool = player:hud_add({
		[hud_type_field_name] = "image",
		position = position,
		scale = { x = 1, y = 1 },
		alignment = { x = 1, y = 1 },
	})
	self.tool_in_hand = player:hud_add({
		[hud_type_field_name] = "image",
		position = position,
		scale = { x = 1, y = 1 },
		alignment = { x = 1, y = 1 },
	})
	self.pointed_thing = "ignore"
	self.pointed_thing_pos = nil
	self.lines = {}
	self.previous_infotext = ""
	self.size_of = { x = 0, y = 0 }
	self.possible_tools = {}
	self.possible_tool_index = 1

	local period = tonumber(minetest.settings:get("what_is_this_uwu_rate_of_change")) or 1.0
	self.timer = Timer.new(period, function()
		if #self.possible_tools == 0 then
			return
		end
		self.possible_tool_index = (self.possible_tool_index % #self.possible_tools) + 1
		self:show_possible_tools()
	end)

	local tech = minetest.settings:get_bool("what_is_this_uwu_spring", true)
	if tech then
		self.scale = {
			x = Spring.new(0.8, 5, self.frame.scale.x),
			y = Spring.new(0.8, 5, self.frame.scale.y),
		}
	end

	return self
end

function player_hud:size(size, y_size, previously_hidden)
	local player = self.player
	local frame = self.frame

	local alignment = self.alignment
	local offset = self.offset

	local DEFAULT_OFFSET = 8

	local x_scale = (size / 16 + 6) * DEFAULT_OFFSET
	local y_scale = y_size * DEFAULT_OFFSET

	self.size_of = {
		x = x_scale,
		y = y_scale,
	}

	local offset_x = offset.x + math.sign(alignment.x) * x_scale
	local offset_y = offset.y + math.sign(alignment.y) * y_scale

	local left_x = -x_scale + offset_x
	local right_x = x_scale + offset_x
	local top_y = y_scale + offset_y
	local bottom_y = -y_scale + offset_y

	player:hud_change(self.image, "offset", {
		x = left_x + 2,
		y = offset_y,
	})
	player:hud_change(self.name, "offset", {
		x = left_x + 48,
		y = bottom_y + 13,
	})

	local tool_x = right_x - 17
	local tool_y = bottom_y + 1
	player:hud_change(self.best_tool, "offset", {
		x = tool_x,
		y = tool_y,
	})
	player:hud_change(self.tool_in_hand, "offset", {
		x = tool_x,
		y = tool_y,
	})
	self:position_additional_info_lines()

	x_scale = x_scale / DEFAULT_OFFSET
	y_scale = y_scale / DEFAULT_OFFSET
	if not self.scale then
		frame:change_size({ x = x_scale, y = y_scale })
		return
	end

	if previously_hidden then
		frame:change_size({ x = x_scale, y = y_scale })
		self.scale.x:setGoal(x_scale)
		self.scale.y:setGoal(y_size)

		self.scale.x:step(100000)
		self.scale.y:step(100000)
		return
	end

	self.scale.x:setGoal(x_scale)
	self.scale.y:setGoal(y_scale)
end

function player_hud:create_line(data)
	local is_progress_bar = data.progress_bar or false
	local text = data.text or ""
	local percent = data.percent or 0
	local hex = data.hex or "0xffffff"

	percent = tonumber(percent) or 0

	local player = self.player
	if is_progress_bar then
		table.insert(self.lines, {
			type = "progress_bar",
			percent = percent,
			behind_bar = player:hud_add({
				[hud_type_field_name] = "image",
				position = self.position,
				scale = { x = 1, y = 1 },
				alignment = { x = 1 },
				text = "wit_progress_bar.png^[multiply:#3d373c",
			}),
			bar = player:hud_add({
				[hud_type_field_name] = "image",
				position = self.position,
				scale = { x = 1, y = 1 },
				alignment = { x = 1 },
				text = "wit_progress_bar.png^[multiply:#" .. hex:sub(3),
			}),
			bar_text = player:hud_add({
				[hud_type_field_name] = "text",
				position = self.position,
				number = 0xffffff,
				scale = { x = 1, y = 1 },
				alignment = { x = 1 },
				text = text,
			}),
		})
		return
	end

	table.insert(self.lines, {
		type = "text",
		line_text = player:hud_add({
			[hud_type_field_name] = "text",
			number = 0xc4c4c4,
			position = self.position,
			scale = { x = 1, y = 1 },
			alignment = { x = 1 },
			text = text,
		}),
	})
end

function player_hud:delete_old_lines()
	local player = self.player
	local old_line_hud_ids = self.lines
	if old_line_hud_ids and player then
		for _ = #old_line_hud_ids, 1, -1 do
			local elem = old_line_hud_ids[1]
			if elem.type == "text" then
				player:hud_remove(elem.line_text)
			else
				player:hud_remove(elem.behind_bar)
				player:hud_remove(elem.bar)
				player:hud_remove(elem.bar_text)
			end
			table.remove(self.lines, 1)
		end
	end
end

function player_hud:parse_additional_info(text)
	self:delete_old_lines()
	if text == nil or text == "" then
		return
	end

	local lines = {}
	for line in text:gmatch("[^\n]+") do
		table.insert(lines, line)
	end

	for _, line in ipairs(lines) do
		if line:find("progressbar") ~= nil then
			local percent, hex, bar_text = WhatIsThisApi.parse_string(line)
			if percent ~= nil and hex ~= nil then
				self:create_line({
					progress_bar = true,
					text = bar_text,
					hex = hex,
					percent = percent,
				})
			end
		else
			self:create_line({
				progress_bar = false,
				text = line,
			})
		end
	end

	self:position_additional_info_lines()
end

function player_hud:handle_spring(dt)
	if not self.scale then
		return
	end
	self.scale.x:step(dt)
	self.scale.y:step(dt)

	self.frame:change_size({
		x = self.scale.x:getPosition(),
		y = self.scale.y:getPosition(),
	})
end

function player_hud:on_step(dt)
	self.timer:on_step(dt)

	if self.shown_on_screen and self.pointed_thing_pos ~= nil then
		self:set_additional_info(self.pointed_thing_pos)
	end

	self:handle_spring(dt)
end

function player_hud:position_additional_info_lines()
	local player = self.player
	local y_step = 18

	local alignment = self.alignment
	local offset = self.offset

	local DEFAULT_OFFSET = 8

	local x_scale = self.size_of.x
	local y_scale = self.size_of.y

	local offset_x = offset.x + math.sign(alignment.x) * x_scale
	local offset_y = offset.y + math.sign(alignment.y) * y_scale

	local left_x = -x_scale + offset_x
	local right_x = x_scale + offset_x
	local top_y = y_scale + offset_y
	local bottom_y = -y_scale + offset_y

	for i, line in ipairs(self.lines) do
		local x = left_x + 48
		local y = bottom_y + 29 + (i - 1) * y_step
		if line.type == "text" and line.line_text then
			player:hud_change(line.line_text, "offset", { x = x, y = y })
		elseif line.type == "progress_bar" then
			local line_scale_x = (x_scale / DEFAULT_OFFSET) - 3.4
			if line.behind_bar then
				player:hud_change(line.behind_bar, "offset", { x = x, y = y })
				player:hud_change(line.behind_bar, "scale", { x = line_scale_x, y = 1 })
			end
			if line.bar then
				player:hud_change(line.bar, "offset", { x = x, y = y })
				player:hud_change(line.bar, "scale", { x = line_scale_x * (line.percent / 100), y = 1 })
			end
			if line.bar_text then
				player:hud_change(line.bar_text, "offset", { x = x, y = y - 1 })
			end
		end
	end

	--considered additional info
	local mod_offset_y = 0
	if #self.lines == 0 then
		mod_offset_y = -10
	end
	player:hud_change(self.mod, "offset", {
		x = left_x + 48,
		y = top_y - 10 + mod_offset_y,
	})
end

function player_hud:set_additional_info(pos)
	local what_is_this_info = WhatIsThisApi.get_info(pos)
	if self.previous_infotext ~= what_is_this_info then
		self:parse_additional_info(what_is_this_info or "")
	end
	self.previous_infotext = what_is_this_info or ""
end

function player_hud:hide()
	for _, element in pairs(self) do
		if type(element) == "number" then
			self.player:hud_change(element, "text", "")
		end
	end

	self.pointed_thing = "ignore"
	self.pointed_thing_pos = nil
	self.frame:hide()
	self.shown_on_screen = false
	self:delete_old_lines()
end

function player_hud:show()
	self.frame:show()
	self.shown_on_screen = true
end

function player_hud:show_possible_tools(options)
	local player = self.player

	if
		(options and options.hide)
		or not self.form_view
		or self.form_view == ""
		or not self.pointed_thing
		or self.pointed_thing == ""
		or self.pointed_thing == "ignore"
	then
		player:hud_change(self.best_tool, "text", "")
		player:hud_change(self.tool_in_hand, "text", "")
		return
	end

	local node_name = self.pointed_thing
	local item_def = minetest.registered_items[node_name]
	local groups = item_def and item_def.groups or {}

	self.possible_tools = {}
	for toolname, tooldef in pairs(minetest.registered_tools) do
		local caps = tooldef.tool_capabilities and tooldef.tool_capabilities.groupcaps
		if caps then
			for group in pairs(groups) do
				if caps[group] then
					table.insert(self.possible_tools, toolname)
					break
				end
			end
		end
	end

	local wielded_item = player:get_wielded_item()
	local item_name = wielded_item:get_name()
	local correct_tool_in_hand = false
	local liquids = { "default:water_source", "default:river_water_source", "default:lava_source" }
	if table.concat(liquids, ","):find(node_name) then
		self.possible_tools = { "bucket:bucket_empty" }
		correct_tool_in_hand = (item_name == "bucket:bucket_empty")
	else
		for _, tool in ipairs(self.possible_tools) do
			if item_name == tool then
				correct_tool_in_hand = true
				break
			end
		end
	end

	local tool = self.possible_tools[self.possible_tool_index] or self.possible_tools[1]
	local texture = ""
	if tool then
		texture = (minetest.registered_tools[tool] and minetest.registered_tools[tool].inventory_image)
			or (minetest.registered_craftitems[tool] and minetest.registered_craftitems[tool].inventory_image)
			or ""
	end

	player:hud_change(self.best_tool, "text", texture)
	local correct_tool_texture = (texture ~= "") and (correct_tool_in_hand and "wit_checkmark.png" or "wit_nope.png")
		or ""
	player:hud_change(self.tool_in_hand, "text", correct_tool_texture)
end

return player_hud

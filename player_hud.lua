local hud_type_field_name
if minetest.features.hud_def_type_field then
	-- Minetest 5.9.0 and later
	hud_type_field_name = "type"
else
	-- All Minetest versions before 5.9.0
	hud_type_field_name = "hud_elem_type"
end

local player_hud = {}
player_hud.__index = player_hud

function player_hud.new(player)
	local self = setmetatable({}, player_hud)

	self.player = player
	self.hidden = false
	self.shown_on_screen = true
	self.frame = Slice9Frame.new({
		side = "wit_side.png",
		center = "wit_center.png",
		edge = "wit_edge.png",
		position = { x = 0.5, y = 0 },
		alignment = { x = 0, y = 1 },
		offset = { x = 0, y = 10 },
		player = player,
	})

	self.image = player:hud_add({
		[hud_type_field_name] = "image",
		position = { x = 0.5, y = 0 },
		scale = { x = 0.3, y = 0.3 },
		offset = { x = -35, y = 35 },
	})
	self.name = player:hud_add({
		[hud_type_field_name] = "text",
		position = { x = 0.5, y = 0 },
		scale = { x = 0.3, y = 0.3 },
		number = 0xffffff,
		alignment = { x = 1 },
		offset = { x = 0, y = 22 },
	})
	self.mod = player:hud_add({
		[hud_type_field_name] = "text",
		position = { x = 0.5, y = 0 },
		scale = { x = 0.3, y = 0.3 },
		number = 0xff3c0a,
		alignment = { x = 1 },
		offset = { x = 0, y = 37 },
		style = 2,
	})
	self.best_tool = player:hud_add({
		[hud_type_field_name] = "image",
		position = { x = 0.5, y = 0 },
		scale = { x = 1, y = 1 },
		alignment = { x = 1, y = 1 },
		offset = { x = 0, y = 51 },
	})
	self.tool_in_hand = player:hud_add({
		[hud_type_field_name] = "image",
		position = { x = 0.5, y = 0 },
		scale = { x = 1, y = 1 },
		alignment = { x = 1, y = 1 },
		offset = { x = 0, y = 51 },
	})
	self.pointed_thing = "ignore"
	self.pointed_thing_pos = nil
	self.lines = {}
	self.previous_infotext = ""
	self.size_of = { x = 0, y = 0 }

	local tech = minetest.settings:get_bool("what_is_this_uwu_spring", true)
	if tech == nil then
		tech = true
	end
	if tech == true then
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
	self.size_of = {
		x = size,
		y = y_size,
	}

	player:hud_change(self.image, "offset", { x = -size / 2 - 25.5, y = 35 + (y_size - 3) * 8 })
	player:hud_change(self.name, "offset", { x = -size / 2 + 2.5, y = 22 })
	local add = 0
	if self.previous_infotext == "" then
		add = -12
	end
	player:hud_change(self.mod, "offset", { x = -size / 2 + 2.5, y = 50 + (y_size - 3) * 16 + add })

	player:hud_change(self.best_tool, "offset", { x = size / 2 + 31.5, y = 12 })
	player:hud_change(self.tool_in_hand, "offset", { x = size / 2 + 31.5, y = 12 })
	self:position_additional_info_lines()

	if not self.scale then
		frame:change_size({ x = size / 16 + 6, y = y_size })
		return
	end

	if previously_hidden then
		frame:change_size({ x = size / 16 + 6, y = y_size })
		self.scale.x:setGoal(size / 16 + 6)
		self.scale.y:setGoal(y_size)

		self.scale.x:step(100000)
		self.scale.y:step(100000)
		return
	end

	self.scale.x:setGoal(size / 16 + 6)
	self.scale.y:setGoal(y_size)
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
				position = { x = 0.5, y = 0 },
				scale = { x = 1, y = 1 },
				alignment = { x = 1, y = 1 },
				text = "wit_progress_bar.png^[multiply:#3d373c",
			}),
			bar = player:hud_add({
				[hud_type_field_name] = "image",
				position = { x = 0.5, y = 0 },
				scale = { x = 1, y = 1 },
				alignment = { x = 1, y = 1 },
				text = "wit_progress_bar.png^[multiply:#" .. hex:sub(3),
			}),
			bar_text = player:hud_add({
				[hud_type_field_name] = "text",
				position = { x = 0.5, y = 0 },
				number = 0xffffff,
				scale = { x = 1, y = 1 },
				alignment = { x = 1, y = 1 },
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
			position = { x = 0.5, y = 0 },
			scale = { x = 1, y = 1 },
			alignment = { x = 1, y = 1 },
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
	--get all lines seperated by \n
	local lines = {}
	for line in text:gmatch("[^\n]+") do
		table.insert(lines, line)
	end

	--check if progress bar text is present in line:
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

function player_hud:on_step(dt)
	if not self.scale then
		return
	end
	self.scale.x:step(dt)
	self.scale.y:step(dt)

	self.frame:change_size({
		x = self.scale.x:getPosition(),
		y = self.scale.y:getPosition(),
	})

	if self.shown_on_screen and self.pointed_thing_pos then
		self:set_additional_info(self.pointed_thing_pos)
	end
end

function player_hud:position_additional_info_lines()
	local player = self.player
	local y_offset = 30
	local y_step = 19
	local size = self.size_of.x or 0
	local y_size = self.size_of.y or 0

	for i, line in ipairs(self.lines) do
		if line.type == "text" and line.line_text then
			player:hud_change(line.line_text, "offset", { x = -size / 2 + 2.5, y = y_offset + (i - 1) * y_step })
		elseif line.type == "progress_bar" then
			if line.behind_bar then
				player:hud_change(
					line.behind_bar,
					"offset",
					{ x = -size / 2 + 2.5, y = y_offset + (i - 1) * y_step + 2 }
				)
				player:hud_change(line.behind_bar, "scale", { x = size / 16 + 2.4, y = 1 })
			end
			if line.bar then
				player:hud_change(line.bar, "offset", { x = -size / 2 + 2.5, y = y_offset + (i - 1) * y_step + 2 })
				player:hud_change(line.bar, "scale", { x = (size / 16 + 2.4) * (line.percent / 100), y = 1 })
			end
			if line.bar_text then
				player:hud_change(line.bar_text, "offset", { x = -size / 2 + 2.5, y = y_offset + (i - 1) * y_step + 1 })
			end
		end
	end

	if #self.lines ~= 0 then
		player:hud_change(self.mod, "offset", { x = -size / 2 + 2.5, y = 50 + (y_size - 3) * 16 })
	else
		player:hud_change(self.mod, "offset", { x = -size / 2 + 2.5, y = 50 + (y_size - 3) * 16 - 12 })
	end
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

return player_hud

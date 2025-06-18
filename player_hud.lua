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
	self.tween = tween
	self.hidden = false
	self.shown_on_screen = true
	self.frame = FrameApi.construct({
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
	self.additional_info = player:hud_add({
		[hud_type_field_name] = "text",
		position = { x = 0.5, y = 0 },
		alignment = { x = 1, y = 1 },
		number = 0xc4c4c4,
		offset = { x = 0, y = 65 },
	})
	self.pointed_thing = "ignore"

	local tech = minetest.settings:get_bool("what_is_this_uwu_spring")
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

	player:hud_change(self.image, "offset", { x = -size / 2 - 25.5, y = 35 + (y_size - 3) * 8 })
	player:hud_change(self.name, "offset", { x = -size / 2 + 2.5, y = 22 })
	player:hud_change(self.additional_info, "offset", { x = -size / 2 + 2.5, y = 30 })
	player:hud_change(self.mod, "offset", { x = -size / 2 + 2.5, y = 50 + (y_size - 3) * 16 })

	player:hud_change(self.best_tool, "offset", { x = size / 2 + 31.5, y = 12 })
	player:hud_change(self.tool_in_hand, "offset", { x = size / 2 + 31.5, y = 12 })

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
end

function player_hud:hide()
	for _, element in pairs(self) do
		if type(element) == "number" then
			self.player:hud_change(element, "text", "")
		end
	end

	self.pointed_thing = "ignore"
	self.frame:hide()
	self.shown_on_screen = false
end

function player_hud:show()
	self.frame:show()
	self.shown_on_screen = true
end

return player_hud

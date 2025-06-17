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

	local tween = Be2eenApi.Tween()
	tween.interpolation = Be2eenApi.Interpolations.cubic_out
	tween.duration = 0.2

	self.player = player
	self.tween = tween
	self.hidden = false
	self.frame = FrameApi.construct({
		side = "wit_side.png",
		center = "wit_center.png",
		edge = "wit_edge.png",
		position = { x = 0.5, y = 0 },
		offset = { x = 0, y = 35 },
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

	return self
end

function player_hud:size(size)
	local player = self.player
	local frame = self.frame

	player:hud_change(self.image, "offset", { x = -size / 2 - 25.5, y = 35 })
	player:hud_change(self.name, "offset", { x = -size / 2 + 2.5, y = 22 })
	player:hud_change(self.mod, "offset", { x = -size / 2 + 2.5, y = 37 })

	player:hud_change(self.best_tool, "offset", { x = size / 2 + 31.5, y = 12 })
	player:hud_change(self.tool_in_hand, "offset", { x = size / 2 + 31.5, y = 12 })

	local tech = minetest.settings:get_bool("what_is_this_uwu_tween", false)
	if tech == false then
		local scaling = size / 16 + 6
		frame:change_size({ x = scaling, y = 3 })
		return
	end

	local tween = self.tween
	if tween:is_running() then
		tween:stop()
	end

	function tween:onStep()
		local scaling = self:get_animated(frame.scale.x, size / 16 + 6)
		frame:change_size({ x = scaling, y = 3 })
	end
	tween:start()
end

function player_hud:hide()
	for _, element in pairs(self) do
		if type(element) == "number" then
			self.player:hud_change(element, "text", "")
		end
	end

	self.pointed_thing = "ignore"
	self.frame:hide()
end

function player_hud:show()
	self.frame:show()
end

return player_hud

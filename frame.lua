local hud_type_field_name
if minetest.features.hud_def_type_field then
	hud_type_field_name = "type"
else
	hud_type_field_name = "hud_elem_type"
end

FrameApi = {}
FrameApi.__index = FrameApi

function FrameApi.construct(data)
	local self = setmetatable({}, FrameApi)

	local position = data.position or { x = 0, y = 0 }
	local player = data.player
	local offset = data.offset or { x = 0, y = 0 }
	local alignment = data.alignment or { x = 0, y = 0 }

	self.scale = { x = 1, y = 1 }
	self.offset = offset
	self.alignment = alignment
	self.player = player

	self.hud_images = {
		left = data.side,
		right = data.side .. "^[transform4",
		top = data.side .. "^[transform1",
		bottom = data.side .. "^[transform3",
		bottom_left = data.edge .. "^[transform6",
		bottom_right = data.edge .. "^[transform2",
		top_left = data.edge,
		top_right = data.edge .. "^[transform3",
		center = data.center,
	}
	self.hud = {
		left = player:hud_add({
			[hud_type_field_name] = "image",
			position = position,
			scale = { x = 1, y = 1 },
			text = data.side,
			offset = { x = -8 + offset.x, y = 0 + offset.y },
			alignment = { x = -1 },
		}),
		right = player:hud_add({
			[hud_type_field_name] = "image",
			position = position,
			scale = { x = 1, y = 1 },
			text = data.side .. "^[transform4",
			offset = { x = 8 + offset.x, y = 0 + offset.y },
			alignment = { x = 1 },
		}),
		top = player:hud_add({
			[hud_type_field_name] = "image",
			position = position,
			scale = { x = 1, y = 1 },
			text = data.side .. "^[transform1",
			offset = { x = 0 + offset.x, y = 8 + offset.y },
			alignment = { x = 0, y = 1 },
		}),
		bottom = player:hud_add({
			[hud_type_field_name] = "image",
			position = position,
			scale = { x = 1, y = 1 },
			text = data.side .. "^[transform3",
			offset = { x = 0 + offset.x, y = -8 + offset.y },
			alignment = { x = 0, y = -1 },
		}),
		top_left = player:hud_add({
			[hud_type_field_name] = "image",
			position = position,
			scale = { x = 1, y = 1 },
			text = data.edge,
			offset = { x = -8 + offset.x, y = -8 + offset.y },
			alignment = { x = -1, y = -1 },
		}),
		top_right = player:hud_add({
			[hud_type_field_name] = "image",
			position = position,
			scale = { x = 1, y = 1 },
			text = data.edge .. "^[transform3",
			offset = { x = 8 + offset.x, y = -8 + offset.y },
			alignment = { x = 1, y = -1 },
		}),
		bottom_right = player:hud_add({
			[hud_type_field_name] = "image",
			position = position,
			scale = { x = 1, y = 1 },
			text = data.edge .. "^[transform2",
			offset = { x = 8 + offset.x, y = 8 + offset.y },
			alignment = { x = 1, y = 1 },
		}),
		bottom_left = player:hud_add({
			[hud_type_field_name] = "image",
			position = position,
			scale = { x = 1, y = 1 },
			text = data.edge .. "^[transform6",
			offset = { x = -8 + offset.x, y = 8 + offset.y },
			alignment = { x = -1, y = 1 },
		}),
		center = player:hud_add({
			[hud_type_field_name] = "image",
			position = position,
			scale = { x = 1, y = 1 },
			text = data.center,
			offset = { x = 0 + offset.x, y = 0 + offset.y },
			alignment = alignment,
		}),
	}
	return self
end

function FrameApi:change_size(scale)
	local player = self.player
	local DEFAULT_OFFSET = 8

	local offset_y = self.offset.y
	local offset_x = self.offset.x

	if self.alignment.y == 1 then
		offset_y = offset_y + scale.y * DEFAULT_OFFSET
	elseif self.alignment.y == -1 then
		offset_y = offset_y - scale.y * DEFAULT_OFFSET
	end

	if self.alignment.x == 1 then
		offset_x = offset_x + scale.x * DEFAULT_OFFSET
	elseif self.alignment.x == -1 then
		offset_x = offset_x - scale.x * DEFAULT_OFFSET
	end

	player:hud_change(self.hud.center, "scale", { x = scale.x, y = scale.y })

	player:hud_change(self.hud.left, "offset", { x = -scale.x * DEFAULT_OFFSET + offset_x, y = offset_y })
	player:hud_change(self.hud.left, "scale", { x = 1, y = scale.y })

	player:hud_change(self.hud.right, "offset", { x = scale.x * DEFAULT_OFFSET + offset_x, y = offset_y })
	player:hud_change(self.hud.right, "scale", { x = 1, y = scale.y })

	player:hud_change(self.hud.top, "offset", { x = offset_x, y = scale.y * DEFAULT_OFFSET + offset_y })
	player:hud_change(self.hud.top, "scale", { x = scale.x, y = 1 })

	player:hud_change(self.hud.bottom, "offset", { x = offset_x, y = -scale.y * DEFAULT_OFFSET + offset_y })
	player:hud_change(self.hud.bottom, "scale", { x = scale.x, y = 1 })

	player:hud_change(
		self.hud.top_left,
		"offset",
		{ x = -scale.x * DEFAULT_OFFSET + offset_x, y = -scale.y * DEFAULT_OFFSET + offset_y }
	)
	player:hud_change(self.hud.top_left, "scale", { x = 1, y = 1 })

	player:hud_change(
		self.hud.top_right,
		"offset",
		{ x = scale.x * DEFAULT_OFFSET + offset_x, y = -scale.y * DEFAULT_OFFSET + offset_y }
	)
	player:hud_change(self.hud.top_right, "scale", { x = 1, y = 1 })

	player:hud_change(
		self.hud.bottom_right,
		"offset",
		{ x = scale.x * DEFAULT_OFFSET + offset_x, y = scale.y * DEFAULT_OFFSET + offset_y }
	)
	player:hud_change(self.hud.bottom_right, "scale", { x = 1, y = 1 })

	player:hud_change(
		self.hud.bottom_left,
		"offset",
		{ x = -scale.x * DEFAULT_OFFSET + offset_x, y = scale.y * DEFAULT_OFFSET + offset_y }
	)
	player:hud_change(self.hud.bottom_left, "scale", { x = 1, y = 1 })

	self.scale = scale
end

function FrameApi:hide()
	for _, elem in pairs(self.hud) do
		self.player:hud_change(elem, "text", "")
	end
end

function FrameApi:show()
	for name, elem in pairs(self.hud) do
		self.player:hud_change(elem, "text", self.hud_images[name])
	end
end

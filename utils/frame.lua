Slice9Frame = {}
do
	Slice9Frame.__index = Slice9Frame

	local minetest = minetest
	local hud_type_field_name = minetest.features.hud_def_type_field and "type" or "hud_elem_type"
	local sign = math.sign

	local function get_vec2(tbl, default_x, default_y)
		default_x = default_x or 0
		default_y = default_y or 0
		return { x = (tbl and tbl.x) or default_x, y = (tbl and tbl.y) or default_y }
	end

	local function hud_add_image(player, position, alignment, offset)
		return player:hud_add({
			[hud_type_field_name] = "image",
			position = position,
			alignment = alignment,
			offset = offset,
		})
	end

	function Slice9Frame.new(data)
		local self = setmetatable({}, Slice9Frame)

		local player = data.player
		local position = get_vec2(data.position)
		local offset = get_vec2(data.offset)
		local alignment = get_vec2(data.alignment)

		self.scale = { x = 1, y = 1 }
		self.offset = offset
		self.alignment = alignment
		self.player = player
		self.hud_images = self:_init_hud_images(data)
		self.hud = self:_init_hud(player, position, alignment, offset)

		self:change_size(self.scale)
		self:show()

		return self
	end

	function Slice9Frame:_init_hud_images(data)
		return {
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
	end

	function Slice9Frame:_init_hud(player, position, alignment, offset)
		local function add_image(_alignment, _offset)
			return hud_add_image(player, position, _alignment, _offset or { x = 0, y = 0 })
		end
		return {
			left = add_image({ x = -1 }),
			right = add_image({ x = 1 }),
			top = add_image({ y = 1 }),
			bottom = add_image({ y = -1 }),
			top_left = add_image({ x = -1, y = -1 }),
			top_right = add_image({ x = 1, y = -1 }),
			bottom_right = add_image({ x = 1, y = 1 }),
			bottom_left = add_image({ x = -1, y = 1 }),
			center = add_image(alignment, offset),
		}
	end

	function Slice9Frame:change_size(scale)
		local player = self.player
		local DEFAULT_OFFSET = 8

		local offset_x = self.offset.x + sign(self.alignment.x) * scale.x * DEFAULT_OFFSET
		local offset_y = self.offset.y + sign(self.alignment.y) * scale.y * DEFAULT_OFFSET

		local x_scale = scale.x * DEFAULT_OFFSET
		local y_scale = scale.y * DEFAULT_OFFSET

		local left_x = -x_scale + offset_x
		local right_x = x_scale + offset_x
		local top_y = y_scale + offset_y
		local bottom_y = -y_scale + offset_y

		local offsets = {
			left = { x = left_x, y = offset_y },
			right = { x = right_x, y = offset_y },
			top = { x = offset_x, y = top_y },
			bottom = { x = offset_x, y = bottom_y },
			top_left = { x = left_x, y = bottom_y },
			top_right = { x = right_x, y = bottom_y },
			bottom_right = { x = right_x, y = top_y },
			bottom_left = { x = left_x, y = top_y },
			center = self.offset,
		}

		local scales = {
			left = { x = 1, y = scale.y },
			right = { x = 1, y = scale.y },
			top = { x = scale.x, y = 1 },
			bottom = { x = scale.x, y = 1 },
			top_left = { x = 1, y = 1 },
			top_right = { x = 1, y = 1 },
			bottom_right = { x = 1, y = 1 },
			bottom_left = { x = 1, y = 1 },
			center = { x = scale.x, y = scale.y },
		}

		for name, hud_id in pairs(self.hud) do
			player:hud_change(hud_id, "offset", offsets[name])
			player:hud_change(hud_id, "scale", scales[name])
		end

		self.scale = scale
	end

	function Slice9Frame:hide()
		for _, elem in pairs(self.hud) do
			self.player:hud_change(elem, "text", "")
		end
	end

	function Slice9Frame:show()
		for name, elem in pairs(self.hud) do
			self.player:hud_change(elem, "text", self.hud_images[name])
		end
	end
end

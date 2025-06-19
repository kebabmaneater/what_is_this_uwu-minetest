ProgressBar = {}
do
	ProgressBar.__index = ProgressBar

	local minetest = minetest
	local hud_type_field_name = minetest.features.hud_def_type_field and "type" or "hud_elem_type"

	function ProgressBar.new(data)
		local self = setmetatable({}, ProgressBar)

		local player = data.player
		self.player = player
		self.text = data.text or ""
		self.percent = data.percent or 0
		self.position = data.position or { x = 0.5, y = 0.5 }
		self.alignment = data.alignment or { x = 0, y = 0 }

		self.hud = {
			behind_bar = player:hud_add({
				[hud_type_field_name] = "image",
				text = data.progress_bar,
			}),
			bar = player:hud_add({
				[hud_type_field_name] = "image",
				text = data.progress_bar,
			}),
			bar_text = player:hud_add({
				[hud_type_field_name] = "text",
				number = data.number or "#FFFFFF",
			}),
		}

		self:set_text(self.text)
		self:set_progress(self.percent)
		self:set_position(self.position)

		return self
	end

	function ProgressBar:set_progress(percentage) end

	function ProgressBar:get_progress()
		return 0
	end

	function ProgressBar:set_text(text)
		-- Placeholder for setting text on the progress bar
	end

	function ProgressBar:set_color(hex) end

	function ProgressBar:set_position(position) end

	function ProgressBar:set_scale(scale)
		-- Placeholder for setting scale of the progress bar
	end
end

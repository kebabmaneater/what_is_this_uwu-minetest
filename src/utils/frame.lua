local M = {}

function M.calculate_hud_height(info)
	local y_size = 3
	if info and info ~= "" then
		y_size = y_size + 1.25 * select(2, info:gsub("\n", "")) + 0.4
	end
	return y_size
end

return M

local function get_vec2(tbl, default_x, default_y)
	default_x = default_x or 0
	default_y = default_y or 0
	return { x = (tbl and tbl.x) or default_x, y = (tbl and tbl.y) or default_y }
end

return {
	get_vec2 = get_vec2,
}

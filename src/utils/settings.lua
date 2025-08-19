local M = {}

function M.get_setting_or(name, default)
	local value = minetest.settings:get("what_is_this_uwu_" .. name) or default
	return tonumber(value) or value
end

function M.get_setting(name)
	return minetest.settings:get("what_is_this_uwu_" .. name)
end

function M.apply_text_multiplier(size)
	local mult = tonumber(minetest.settings:get("what_is_this_uwu_text_multiplier"))
	if mult then
		return math.ceil(size * mult)
	end
	return size
end

function M.apply_technical_name(desc, name)
	local tech = minetest.settings:get_bool("what_is_this_uwu_itemname", false)
	if tech and desc ~= "" then
		return desc .. " [" .. name .. "]"
	end
	return desc
end

return M

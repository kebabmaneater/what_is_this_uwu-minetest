local function get_setting_or(name, default)
	local value = minetest.settings:get("what_is_this_uwu_" .. name) or default
	return tonumber(value) or value
end

local function get_setting(name)
	return minetest.settings:get("what_is_this_uwu_" .. name)
end

return {
	get_setting_or = get_setting_or,
	get_setting = get_setting,
}

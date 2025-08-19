local modpath = minetest.get_modpath("what_is_this_uwu")
local utils = modpath .. "/src/utils/"

return {
	entity = dofile(utils .. "entity.lua"),
	frame = dofile(utils .. "frame.lua"),
	settings = dofile(utils .. "settings.lua"),
	spring = dofile(utils .. "spring.lua"),
	string = dofile(utils .. "string.lua"),
	timer = dofile(utils .. "timer.lua"),
}

local modpath = minetest.get_modpath("what_is_this_uwu")
local utils = modpath .. "/src/utils/"

return {
	entity = dofile(utils .. "entity.lua"),
	settings = dofile(utils .. "settings.lua"),
	string = dofile(utils .. "string.lua"),
	frame = dofile(utils .. "frame.lua"),
	vector = dofile(utils .. "vector.lua"),
}

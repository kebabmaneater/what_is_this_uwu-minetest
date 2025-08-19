local modpath = minetest.get_modpath("what_is_this_uwu")
local classes = modpath .. "/src/classes/"

return {
	frame = dofile(classes .. "frame.lua"),
	spring = dofile(classes .. "spring.lua"),
	timer = dofile(classes .. "timer.lua"),
}

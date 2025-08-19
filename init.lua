local minetest = minetest
local modpath = minetest.get_modpath("what_is_this_uwu")

dofile(modpath .. "/src/api.lua")
local utils = dofile(modpath .. "/src/utils/utils.lua")

local hud_handler = dofile(modpath .. "/src/hud_handler.lua")
hud_handler.init({
	utils = utils,
	player_hud = dofile(modpath .. "/src/hud/player_hud.lua"),
	what_is_this_uwu = dofile(modpath .. "/src/hud/hud_updater.lua"),
})

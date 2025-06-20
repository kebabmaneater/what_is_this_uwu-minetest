local minetest = minetest
local modpath = minetest.get_modpath("what_is_this_uwu")

dofile(modpath .. "/api.lua")
local what_is_this_uwu = dofile(modpath .. "/help.lua")
local player_hud = dofile(modpath .. "/player_hud.lua")

local huds = {}

minetest.register_on_joinplayer(function(player)
	huds[player:get_player_name()] = player_hud.new(player)
end)

minetest.register_on_leaveplayer(function(player)
	huds[player:get_player_name()] = nil
end)

minetest.register_globalstep(function(dtime)
	for _, player in pairs(minetest.get_connected_players()) do
		local hud = huds[player:get_player_name()]
		if hud then
			hud:on_step(dtime)
			what_is_this_uwu.update_hud(player, huds)
		end
	end
end)

minetest.register_chatcommand("wituwu", {
	params = "",
	description = "Show and unshow the wituwu pop-up",
	privs = {},
	func = function(name)
		huds[name].hidden = not huds[name].hidden
		return true, "Option flipped"
	end,
})

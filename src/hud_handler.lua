local M = {
	huds = {},
}

local function register_command()
	local huds = M.huds

	minetest.register_chatcommand("wituwu", {
		params = "",
		description = "Show and unshow the wituwu pop-up",
		privs = {},
		func = function(name)
			huds[name].hidden = not huds[name].hidden
			return true, "Option flipped"
		end,
	})
end

local function create_new_hud(player)
	local get_setting_or = M.utils.settings.get_setting_or
	local player_hud = M.player_hud

	return player_hud.new(player, {
		position = { x = get_setting_or("position_x", 0.5), y = get_setting_or("position_y", 0) },
		alignment = { x = get_setting_or("alignment_x", 0), y = get_setting_or("alignment_y", 1) },
		offset = { x = get_setting_or("offset_x", 0), y = get_setting_or("offset_y", 10) },
	})
end

local function on_join(player)
	local huds = M.huds
	local hud = create_new_hud(player)
	huds[player:get_player_name()] = hud
end

local function on_leave(player)
	local huds = M.huds
	huds[player:get_player_name()] = nil
end

local function register_global_step(dtime)
	local huds = M.huds
	local what_is_this_uwu = M.what_is_this_uwu

	for _, player in pairs(minetest.get_connected_players()) do
		what_is_this_uwu.update_hud(player, huds, dtime)
	end
end

function M.init(modules)
	M.utils = modules.utils
	M.what_is_this_uwu = modules.what_is_this_uwu
	M.player_hud = modules.player_hud

	M.what_is_this_uwu.init(modules.utils)
	M.player_hud.init(modules.utils)

	minetest.register_on_joinplayer(on_join)
	minetest.register_on_leaveplayer(on_leave)
	minetest.register_globalstep(register_global_step)
	register_command()
end

return M

local minetest = core or minetest

WhatIsThisApi = {}

function WhatIsThisApi.get_info(node_position)
	local meta = minetest.get_meta(node_position)
	if not meta then
		return nil
	end

	local info = meta:get_string("what_is_this_info")
	if info == "" then
		info = meta:get_string("infotext")
	end
	return info
end

function WhatIsThisApi.set_info(node_position, info)
	local meta = minetest.get_meta(node_position)
	if not meta then
		return nil
	end

	meta:set_string("what_is_this_info", info)
end

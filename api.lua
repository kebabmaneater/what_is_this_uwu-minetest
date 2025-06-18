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

function WhatIsThisApi.parse_string(str)
	-- accepts a progress bar as a string and returns the percentage, color and text
	-- Example input: ^[progressbar(66.6)(0xc4c4c4)[Item: 66%]

	str = str:gsub("\n", "")
	local percent = str:match("progressbar%(([%d%.]+)%)")
	local hex = str:match("%((0x%x+)%)")
	local text = str:match("%[(.*)%]$")
	percent = percent and tonumber(percent) or nil
	return percent, hex, text
end

function WhatIsThisApi.get_progress_bar_string(percent, hex, text)
	-- accepts a percentage, hex color and text and returns a progress bar string
	-- Example output: ^[progressbar(66.6)(0xc4c4c4)[Item: 66%]

	if not percent or not hex or not text then
		return ""
	end

	return string.format("^[progressbar(%.1f)(%s)[%s]", percent, hex, text)
end

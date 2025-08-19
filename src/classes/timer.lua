---@class Timer
---@field timer number
---@field period number
---@field callback fun()
local M = {}
M.__index = M

---Create a new Timer.
---@param period number
---@param callback fun()
---@return Timer
function M.new(period, callback)
	local self = setmetatable({}, M)
	self.timer = 0
	self.period = period
	self.callback = callback
	return self
end

---Advance the timer by dtime and call callback if period elapsed.
---@param dtime number
function M:on_step(dtime)
	local timer = self.timer
	local callback = self.callback
	local period = self.period

	timer = timer + dtime
	if timer >= period then
		callback()
		timer = timer - period
	end
	self.timer = timer
end

return M

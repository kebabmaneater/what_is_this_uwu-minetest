---@class Timer
---@field timer number
---@field period number
---@field callback fun()
Timer = {}

do
	Timer.__index = Timer

	---Create a new Timer.
	---@param period number
	---@param callback fun()
	---@return Timer
	function Timer.new(period, callback)
		local self = setmetatable({}, Timer)
		self.timer = 0
		self.period = period
		self.callback = callback
		return self
	end

	---Advance the timer by dtime and call callback if period elapsed.
	---@param dtime number
	function Timer:on_step(dtime)
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
end

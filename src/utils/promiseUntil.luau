local Packages = script.Parent.Parent.Parent.Packages
local Promise = require(Packages.promise)
local Constants = require(script.Parent.Parent.Constants)

type Promise<T> = typeof(Promise.new)

-- Polls `condition()` every `interval` seconds until it returns a truthy value.
-- Resolves with the returned value, or rejects after `timeout` seconds.
return function(condition: () -> any?, timeout: number, interval: number?): Promise<any>
	local step = interval or Constants.POLL_INTERVAL

	return Promise.new(function(resolve, reject)
		local elapsed = 0
		task.spawn(function()
			while elapsed < timeout do
				local result = condition()
				if result then
					resolve(result)
					return
				end
				task.wait(step)
				elapsed += step
			end
			reject("timed out waiting for condition")
		end)
	end)
end

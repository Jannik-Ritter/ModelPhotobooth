local promiseUntil = require(script.Parent.promiseUntil)

local INTERVAL = 0.05
local MAX_ATTEMPTS = 100

-- Returns a Promise that resolves when track.Length > 0, or rejects after max attempts.
return function(track: AnimationTrack, maxAttempts: number?)
	local limit = maxAttempts or MAX_ATTEMPTS
	return promiseUntil(function()
		return track.Length > 0
	end, limit * INTERVAL, INTERVAL)
end

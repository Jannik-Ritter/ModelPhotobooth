local promiseUntil = require(script.Parent.promiseUntil)
local Constants = require(script.Parent.Parent.Constants)

-- Returns a Promise that resolves when track.Length > 0, or rejects after max attempts.
return function(track: AnimationTrack, maxAttempts: number?)
	local limit = maxAttempts or Constants.MAX_POLL_ATTEMPTS
	return promiseUntil(function()
		return track.Length > 0
	end, limit * Constants.POLL_INTERVAL, Constants.POLL_INTERVAL)
end

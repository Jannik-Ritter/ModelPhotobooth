local Packages = script.Parent.Parent.Parent.Packages
local React = require(Packages.react)
local Types = require(script.Parent.Parent.Types)

type ToastEntry = Types.ToastEntry

return function()
	local toasts, setToasts = React.useState({} :: { ToastEntry })
	local nextToastId = React.useRef(0)

	local function addToast(variant: string, message: string)
		nextToastId.current += 1
		local id = nextToastId.current
		setToasts(function(prev)
			local next = table.clone(prev)
			table.insert(next, { id = id, variant = variant, message = message })
			return next
		end)
	end

	local function removeToast(id: number)
		setToasts(function(prev)
			local next = {}
			for _, t in ipairs(prev) do
				if t.id ~= id then
					table.insert(next, t)
				end
			end
			return next
		end)
	end

	return {
		toasts = toasts,
		addToast = addToast,
		removeToast = removeToast,
	}
end

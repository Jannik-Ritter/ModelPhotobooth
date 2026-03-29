if not plugin then
	error("[ModelPhotobooth] Right-click -> Save as Local Plugin", 0)
end

local Packages = script.Parent.Parent.Packages
local React = require(Packages._Index["jsdotlua_react@17.2.1"]["react"])
local ReactRoblox = require(Packages._Index["jsdotlua_react-roblox@17.2.1"]["react-roblox"])

local App = require(script.Parent.App)

-- Toolbar
local toolbar = plugin:CreateToolbar("Model Photobooth")
local toggleBtn = toolbar:CreateButton("ModelPhotobooth", "Render Models", "rbxassetid://132844739921945")

-- Widget
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Left,
	false, -- initially disabled
	false, -- don't override saved state
	780,
	520, -- float size
	480,
	300 -- min size
)
local widget = plugin:CreateDockWidgetPluginGuiAsync("MPB_React_v1", widgetInfo)
widget.Title = "Model Photobooth"
widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- React root
local root = ReactRoblox.createRoot(Instance.new("Folder"))

local function mountApp()
	root:render(ReactRoblox.createPortal(React.createElement(App, { plugin = plugin }), widget))
end

local function unmountApp()
	root:unmount()
end

-- Toggle widget
toggleBtn.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

-- Mount when enabled
widget:GetPropertyChangedSignal("Enabled"):Connect(function()
	if widget.Enabled then
		mountApp()
	end
end)

-- Initial mount if saved as enabled
if widget.Enabled then
	mountApp()
end

-- Cleanup
plugin.Unloading:Connect(function()
	unmountApp()
end)

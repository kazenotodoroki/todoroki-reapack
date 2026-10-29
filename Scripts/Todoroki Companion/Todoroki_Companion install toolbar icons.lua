-- @noindex
-- Todoroki Companion: installs (or updates) the dark toolbar icons of every Todoroki package
-- into <REAPER>/Data/toolbar_icons. The Companion also does it by itself when it starts.
local HERE = ({ reaper.get_action_context() })[2]:match("^(.*[\\/])")
local TC = dofile(HERE .. "Todoroki_Companion_API.lua")
local n = TC.install_toolbar_icons(false)
reaper.ShowMessageBox(n .. " toolbar icon files installed in Data/toolbar_icons.\n\n" ..
  "To use them: right click on a toolbar > Customize toolbar... > select a button > Icon...,\n" ..
  "then pick the icon with the same name as the action.", "Todoroki Companion", 0)

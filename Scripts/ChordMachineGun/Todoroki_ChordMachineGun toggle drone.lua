-- @noindex
-- ChordMachineGun — toggle drone
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

setDroneEnabled(not getDroneEnabled())
reaper.Help_Set("ChordMachineGun: drone " .. (getDroneEnabled() and "on" or "off"), false)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

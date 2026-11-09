-- @noindex
-- ChordMachineGun 2 — toggle color sus2
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

local on = toggleColor("sus2")
reaper.Help_Set("ChordMachineGun 2: color sus2 " .. (on and "on" or "off"), false)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

-- @noindex
-- ChordMachineGun 2 — toggle color 13th
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

local on = toggleColor("13")
reaper.Help_Set("ChordMachineGun 2: color 13th " .. (on and "on" or "off"), false)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

-- @noindex
-- ChordMachineGun 2 — toggle color sus4
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

local on = toggleColor("sus4")
reaper.Help_Set("ChordMachineGun 2: color sus4 " .. (on and "on" or "off"), false)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

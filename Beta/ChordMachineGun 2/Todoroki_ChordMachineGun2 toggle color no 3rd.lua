-- @noindex
-- ChordMachineGun 2 — toggle color no 3rd
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

local on = toggleColor("no3")
reaper.Help_Set("ChordMachineGun 2: color no 3rd " .. (on and "on" or "off"), false)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

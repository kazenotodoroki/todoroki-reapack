-- @noindex
-- ChordMachineGun 2 — previous insert pattern
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

local pt = cyclePattern(-1)
reaper.Help_Set("ChordMachineGun 2: insert pattern = " .. pt.name, false)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

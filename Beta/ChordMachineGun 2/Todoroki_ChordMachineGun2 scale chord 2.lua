-- @noindex
-- ChordMachineGun 2 — scale chord 2
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

updateScaleData()
scaleChordAction(2)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

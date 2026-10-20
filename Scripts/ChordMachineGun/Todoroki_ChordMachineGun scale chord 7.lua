-- @noindex
-- ChordMachineGun — scale chord 7
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
scaleChordAction(7)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

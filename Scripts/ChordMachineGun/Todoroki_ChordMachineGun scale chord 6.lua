-- @noindex
-- ChordMachineGun — scale chord 6
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
scaleChordAction(6)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

-- @noindex
-- ChordMachineGun — scale chord 4
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
scaleChordAction(4)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

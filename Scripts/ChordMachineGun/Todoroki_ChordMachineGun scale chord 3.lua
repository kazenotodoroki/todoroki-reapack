-- @noindex
-- ChordMachineGun — scale chord 3
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
scaleChordAction(3)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

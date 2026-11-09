-- @noindex
-- ChordMachineGun 2 — decrement scale type
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

updateScaleData()
decrementScaleTypeAction()
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

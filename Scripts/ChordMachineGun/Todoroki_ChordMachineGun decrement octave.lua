-- @noindex
-- ChordMachineGun — decrement octave
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
decrementOctaveAction()
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

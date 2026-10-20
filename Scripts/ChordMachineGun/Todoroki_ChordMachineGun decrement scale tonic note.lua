-- @noindex
-- ChordMachineGun — decrement scale tonic note
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
decrementScaleTonicNoteAction()
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

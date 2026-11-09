-- @noindex
-- ChordMachineGun 2 — lower scale note 6
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

updateScaleData()
lowerScaleNoteAction(6)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

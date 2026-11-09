-- @noindex
-- ChordMachineGun 2 — increment scale tonic note
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

updateScaleData()
incrementScaleTonicNoteAction()
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

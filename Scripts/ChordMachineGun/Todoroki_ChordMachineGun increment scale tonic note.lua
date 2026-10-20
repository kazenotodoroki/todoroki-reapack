-- @noindex
-- ChordMachineGun — increment scale tonic note
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
incrementScaleTonicNoteAction()
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

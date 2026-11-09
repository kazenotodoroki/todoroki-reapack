-- @noindex
-- ChordMachineGun 2 — increment chord type
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

updateScaleData()
incrementChordTypeAction()
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

-- @noindex
-- ChordMachineGun 2 — stop all notes from playing
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

stopAllNotesFromPlaying()
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

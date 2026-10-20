-- @noindex
-- ChordMachineGun — stop all notes from playing
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

stopAllNotesFromPlaying()
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

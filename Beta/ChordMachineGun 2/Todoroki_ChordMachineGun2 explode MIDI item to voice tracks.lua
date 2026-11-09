-- @noindex
-- ChordMachineGun 2 — explode MIDI item to voice tracks
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

explodeTakeToVoiceTracks()
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

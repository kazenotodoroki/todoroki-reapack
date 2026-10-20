-- @noindex
-- ChordMachineGun — explode MIDI item to voice tracks
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

explodeTakeToVoiceTracks()
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

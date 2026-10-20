-- @noindex
-- ChordMachineGun — increment octave
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
incrementOctaveAction()
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

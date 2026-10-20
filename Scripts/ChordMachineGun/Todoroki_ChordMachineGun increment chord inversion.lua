-- @noindex
-- ChordMachineGun — increment chord inversion
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
incrementChordInversionAction()
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

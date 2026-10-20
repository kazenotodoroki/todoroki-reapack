-- @noindex
-- ChordMachineGun — lower scale note 1
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
lowerScaleNoteAction(1)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

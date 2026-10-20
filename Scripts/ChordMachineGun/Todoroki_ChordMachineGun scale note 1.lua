-- @noindex
-- ChordMachineGun — scale note 1
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
scaleNoteAction(1)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

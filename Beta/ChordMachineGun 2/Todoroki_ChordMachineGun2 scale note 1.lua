-- @noindex
-- ChordMachineGun 2 — scale note 1
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

updateScaleData()
scaleNoteAction(1)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

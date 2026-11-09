-- @noindex
-- ChordMachineGun 2 — scale note 4
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

updateScaleData()
scaleNoteAction(4)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

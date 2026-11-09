-- @noindex
-- ChordMachineGun 2 — scale note 3
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

updateScaleData()
scaleNoteAction(3)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

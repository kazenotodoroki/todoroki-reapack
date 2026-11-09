-- @noindex
-- ChordMachineGun 2 — borrowed scale chord 3 (degree 3 of the selected chord's scale)
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

updateScaleData()
borrowedChordAction(3, true)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

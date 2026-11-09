-- @noindex
-- ChordMachineGun 2 — borrowed scale chord 5 (degree 5 of the selected chord's scale)
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

updateScaleData()
borrowedChordAction(5, true)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

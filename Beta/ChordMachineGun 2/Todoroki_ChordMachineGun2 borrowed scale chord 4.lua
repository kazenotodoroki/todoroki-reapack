-- @noindex
-- ChordMachineGun 2 — borrowed scale chord 4 (degree 4 of the selected chord's scale)
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

updateScaleData()
borrowedChordAction(4, true)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

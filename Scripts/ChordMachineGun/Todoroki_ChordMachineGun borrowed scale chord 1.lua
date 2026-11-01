-- @noindex
-- ChordMachineGun — borrowed scale chord 1 (degree 1 of the selected chord's scale)
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
borrowedChordAction(1, true)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

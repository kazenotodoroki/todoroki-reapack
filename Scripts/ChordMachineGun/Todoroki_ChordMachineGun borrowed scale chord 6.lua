-- @noindex
-- ChordMachineGun — borrowed scale chord 6 (degree 6 of the selected chord's scale)
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
borrowedChordAction(6, true)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

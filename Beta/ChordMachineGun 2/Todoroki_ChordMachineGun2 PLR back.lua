-- @noindex
-- ChordMachineGun 2 — go back to the previous PLR anchor chord
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

updateScaleData()
plrBack(true)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

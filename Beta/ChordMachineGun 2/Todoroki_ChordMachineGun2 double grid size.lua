-- @noindex
-- ChordMachineGun 2 — double grid size
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

doubleGridSize()
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

-- @noindex
-- ChordMachineGun 2 — substitution 2 - P - parallel
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

subsAction(2, false)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

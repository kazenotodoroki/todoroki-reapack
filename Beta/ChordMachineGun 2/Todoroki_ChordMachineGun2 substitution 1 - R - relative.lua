-- @noindex
-- ChordMachineGun 2 — substitution 1 - R - relative
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

subsAction(1, false)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

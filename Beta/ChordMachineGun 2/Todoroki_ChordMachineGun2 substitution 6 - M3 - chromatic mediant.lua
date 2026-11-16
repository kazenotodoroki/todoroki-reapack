-- @noindex
-- ChordMachineGun 2 — substitution 6 - M3 - chromatic mediant
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

subsAction(6, false)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

-- @noindex
-- ChordMachineGun 2 — substitution 5 - viio - leading-tone diminished
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

subsAction(5, false)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

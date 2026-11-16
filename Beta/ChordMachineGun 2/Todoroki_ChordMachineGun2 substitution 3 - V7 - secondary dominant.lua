-- @noindex
-- ChordMachineGun 2 — substitution 3 - V7 - secondary dominant
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

subsAction(3, false)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

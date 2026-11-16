-- @noindex
-- ChordMachineGun 2 — substitution 7 - bVII7 - backdoor dominant
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

subsAction(7, false)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

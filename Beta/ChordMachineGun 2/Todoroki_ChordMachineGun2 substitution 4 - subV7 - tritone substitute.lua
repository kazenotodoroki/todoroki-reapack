-- @noindex
-- ChordMachineGun 2 — substitution 4 - subV7 - tritone substitute
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

subsAction(4, false)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

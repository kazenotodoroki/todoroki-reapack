-- @noindex
-- ChordMachineGun 2 — toggle next-chord hints
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

setHintsEnabled(not getHintsEnabled())
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

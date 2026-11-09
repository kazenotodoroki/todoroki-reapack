-- @noindex
-- ChordMachineGun 2 — neo-Riemannian transformation R (relative) from the current anchor
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun2_core.lua")

updateScaleData()
plrAction(3, true, true)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

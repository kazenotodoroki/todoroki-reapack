-- @noindex
-- ChordMachineGun — neo-Riemannian transformation PR (chromatic mediant) from the current anchor
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
plrAction(7, true, true)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

-- @noindex
-- ChordMachineGun — neo-Riemannian transformation L (leading-tone exchange) from the current anchor
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
plrAction(2, true, true)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

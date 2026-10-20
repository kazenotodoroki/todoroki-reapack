-- @noindex
-- ChordMachineGun — transformation néo-riemannienne R (relative) depuis l'ancrage courant
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
plrAction(3, true, true)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)

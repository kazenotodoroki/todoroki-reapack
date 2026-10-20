-- @noindex
-- ChordMachineGun — transformation néo-riemannienne N (nebenverwandt) depuis l'ancrage courant
local path = ({ reaper.get_action_context() })[2]:match("^(.*[/\\])")
dofile(path .. "Todoroki_ChordMachineGun_core.lua")

updateScaleData()
plrAction(4, true, true)
reaper.defer(emptyFunctionToPreventAutomaticCreationOfUndoPoint)
